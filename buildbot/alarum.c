/* Wrapper to reliably execute a Wine conformance test
 * inside an automated test system.
 *
 * Usage:
 *  alarum NNN runtest foo_test.exe foo.c
 *
 * Runs the given test, with the following twists:
 *
 * 1. If the test takes longer than NNN seconds, forcibly
 * kills the test, and prints the message
 *  alarm: Timeout!  Killing child.
 * and exits with status 1.
 * (See e.g. http://bugs.winehq.org/show_bug.cgi?id=15958 )
 *
 * If the test crashes, prints the message
 *  alarum: Terminated abnormally.
 *
 * 2. The test's stdout and stderr are saved to a temporary file,
 * and when the test is done, the test ID the
 * temporary file's contents are output all at once.
 * If the test failed in any way, each line of the test's output
 * (including any timeout or crash message from this program)
 * is prefixed with ']] '.
 *
 * Copyright 2008, Google (Dan Kegel)
 * Copyright 2011, Dan Kegel
 * License: LGPL
 */

#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/file.h>
#include <sys/signal.h>
#include <sys/types.h>
#include <sys/wait.h>

pid_t child_pid;

/* a real implementation would not have a limit on commandline length */
#define MAXARGS 1000

char *newargv[MAXARGS];

static void handler(int x)
{
    fflush(stdout);
    printf("]] alarum: Timeout!  Killing child %s.\n", newargv[0]);
    fflush(stdout);
    /* TODO: This probably won't kill grandchildren.  Do we want to create a process group? */
    kill(child_pid, SIGKILL);
}

/* Extract test id (module:filename) from commandline, return true if ok */
static int getTestID(int argc, char **argv, char *buf)
{
    int i;
    const char *module, *module_end;
    const char *file, *file_end;
    char *p = buf;
    int argi;

    for (argi=1; argi < argc; argi++)
        if (strstr(argv[argi], "wine"))
            break;
    if (argi + 2 >= argc)
        return 0;

    module = argv[argi+1];
    if (!module) return 0;
    module_end = strrchr(module, '_');
    if (!module_end) return 0;

    file = argv[argi+2];
    if (!file) return 0;
    file_end = strrchr(file, '.');
    if (!file_end) return 0;

    while (module != module_end)
      *p++ = *module++;
    *p++ = ':';
    while (file != file_end)
      *p++ = *file++;
    *p = 0;
    return 1;
}

int main(int argc, char **argv)
{
    int newargc;
    int timeout;
    pid_t pid;
    int i;
    int waitresult;
    int ret;
    int logfd;
    FILE *logfp;
    char logfilename[1024];
#define MYBUFLEN 128000
    static char buf[MYBUFLEN];
    time_t t0, t1;
    int valgrinderr;

    if (argc < 3) {
        fprintf(stderr, "Usage: alarum timeout-in-seconds command ...\n");
        exit(1);
    }
    timeout = atoi(argv[1]);
    if (timeout < 1) {
        fprintf(stderr, "Timeout must be positive, was %s\n", argv[1]);
        exit(1);
    }

    /* Prepare new argv with timeout removed. */
    for (newargc=0; newargc < argc-2 && newargc < MAXARGS-1; newargc++)
        newargv[newargc] = argv[newargc+2];
    newargv[newargc] = NULL;

    /* Redirect child's output and stderr to a temporary file ... */
    sprintf(logfilename, "%d.tmplog", getpid());
    logfd = open(logfilename, O_RDWR|O_CREAT, 0660);
    if (logfd == -1) {
        perror(logfilename);
        exit(1);
    }

    time(&t0);

    /* Run test */
    child_pid = fork();
    if (child_pid == 0) {
        /* child */
        /* Finish redirecting */
        dup2(logfd, 1);
        dup2(logfd, 2);
        /* TODO: Do we want to make this its own process group for ease of killing grandchildren? */
        execvp(newargv[0], newargv);
        /* notreached */
        perror(newargv[0]);
        exit(1);
    }

    /* Wait timeout seconds for it to finish */
    signal(SIGALRM, handler);
    alarm(timeout);
    waitresult = 0;
    while ((ret = wait(&waitresult)) == -1 && errno == EINTR)
        ;
    time(&t1);

    if (close(logfd)) {
        perror("closing log fd");
        exit(1);
    }

    logfp = fopen(logfilename, "r");
    if (!logfp) {
        perror(logfilename);
        exit(1);
    }

    /* Check for valgrind errors */
    valgrinderr = 0;
    if (strstr(newargv[0], "valgrind")) {
        char grepcmd[5000];
        int status;
        /* ok, a real programm would use regcomp()/regexec(), but I'm lazy */
        sprintf(grepcmd, "grep -q '==.*ERROR SUMMARY: [1-9]' %s", logfilename);
        status = system(grepcmd);
        if (status != -1 && WIFEXITED(status) && WEXITSTATUS(status) == 0) {
            valgrinderr = 1;
        }
    }

    /* Get an exclusive lock so logs don't get mixed together */
    int loglockfd = open("log.lock", O_RDWR|O_CREAT, 0600);
    if (loglockfd != -1) 
       flock(loglockfd, LOCK_EX);

    if (!WIFEXITED(waitresult) || (WEXITSTATUS(waitresult) != 0)) {
        printf("]] alarum: failed command was ");
        for (i=0; i<newargc; i++) {
            printf("%s ", newargv[i]);
        }
        printf("\n");
    }
    /* Copy the temporary file to stdout, line by line, prepending error status if needed */
    while (fgets(buf, MYBUFLEN, logfp)) {
        if (valgrinderr || !WIFEXITED(waitresult) || (WEXITSTATUS(waitresult) != 0)) {
            printf("]] ");
        }
        fputs(buf, stdout);
    }
    fclose(logfp);

    remove(logfilename);

    /* Report status to stdout in a way that's easy to grep */
    buf[0] = 0;
    for (i=0; i<newargc; i++) {
        strcat(buf, newargv[i]);
        strcat(buf, " ");
    }
    if (!WIFEXITED(waitresult))
        printf("]] alarum: terminated abnormally, command '%s'\n", buf);
    else
        printf("alarum: elapsed time %d seconds, command '%s'\n", (int) (t1 - t0), buf);

    if (loglockfd != -1) 
       flock(loglockfd, LOCK_UN);

    /* Finally, exit with test program's exit code, or 99 if crashed, or 98 if valgrind error */
    if (!WIFEXITED(waitresult))
        return 99;
    if (valgrinderr)
        return 98;
    return WEXITSTATUS(waitresult);
}
