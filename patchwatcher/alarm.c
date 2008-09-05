/* Execute a command with a given timeout, in seconds */
/* Why isn't a command like this included by default in Unix? */
/* Public domain, Dan Kegel, 2008 */

#include <unistd.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>

pid_t child_pid;

void handler(int x)
{
    fprintf(stderr, "Timeout!  Killing child.\n");
    /* TODO: This probably won't kill grandchildren.  Do we want to create a process group? */
    kill(child_pid, SIGKILL);
    exit(1);
}

/* a real implementation would not have a limit on commandline length */
#define MAXARGS 1000

int main(int argc, char **argv)
{
    char *newargv[MAXARGS];
    int timeout;
    pid_t pid;
    int i;
    int waitresult;
    int ret;

    if (argc < 3) {
        fprintf(stderr, "Usage: alarm timeout-in-seconds command ...\n");
        exit(1);
    }
    timeout = atoi(argv[1]);
    if (timeout < 1) {
        fprintf(stderr, "Timeout must be positive, was %s\n", argv[1]);
        exit(1);
    }

    // kludge: reset display
    system("xrandr -s 0");

    for (i=0; i<argc-2 && i<MAXARGS-1; i++)
        newargv[i] = argv[i+2];
    newargv[i] = NULL;

    child_pid = fork();
    if (child_pid == 0) {
        /* child */
        /* TODO: Do we want to make this its own process group for ease of killing grandchildren? */
        execvp(newargv[0], newargv);
        /* notreached */
        perror(newargv[0]);
        exit(1);
    }

    signal(SIGALRM, handler);
    alarm(timeout);
    waitresult = 0;
    /* Probably don't need this loop, but maybe ^Z could interrupt wait */
    while ((ret = wait(&waitresult)) == -1 && errno == EINTR)
        ;
    if (!WIFEXITED(waitresult)) {
        printf("Terminated abnormally\n");
        exit(99);
    }
    exit(WEXITSTATUS(waitresult));
}
