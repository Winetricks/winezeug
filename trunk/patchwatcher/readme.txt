Patchwatcher - a distributed precommit testing system

History

The Wine project has long suffered from a reputation
for being hard to join, and from having lots of 
regressions.  Patches from newcomers often don't get 
reviewed promptly, and are sometimes ignored.
The regression test suite, though large, was full
of tests that didn't even pass on Windows.  And
tools such as Valgrind and Coverity were raising
little red flags about possible problems.

About 2007, the Wine community started focusing
on improving the quality of its test suite and
in fixing warnings from Valgrind and Coverity.
By Wineconf 2008 Wine's test suite actually passing 
on two developers' machines :-)

However, there was no automated system to keep
valgrind errors from sneaking back in to the 
codebase.  The most logical way to prevent that
would be to require all tests to pass under
Valgrind before committing new code to Wine.
But this had to be done without burdening the
maintainer.  The solution was to write a shell
script to watch the wine-patches mailing list and
run the entire Wine test suite on every proposed
patch, and filter out patches which failed tests
or which would introduce new Valgrind warnings.

This shell script, Patchwatcher, is still under 
development, but it's far enough along to be usable
already.  

Most Wine developers don't need to worry about how
to set up Patchwatcher, since a single Patchwatcher
instance can service the entire community.
But Patchwatcher is flexible, and can incorporate
many kinds of analysis; if you have a favorite
operating system or code analysis tool, you can
integrate it into Patchwatcher to give Wine
developers early warning of portability problems
or subtle bugs in their code.

Configuration

1. install all the packages needed to build Wine,
e.g. by running http://kegel.com/wine/hardy.sh

2. install the additional packages needed by Patchwatcher,
e.g. by running patchwatcher/install-pkgs.sh.

3. Make sure you can send mail using 'mailx user@host'.
You may need to do sudo dpkg-reconfigure exim4-config.

4. set up an area on a web site that you can
upload to via FTP

5. create a .netrc that allows you to ftp results to the 
web site without entering a password.

6. Set up a pop3 mailbox somewhere dedicated to your
patchwatcher instance, and subscribe it to wine-patches.

7. Edit patchwatcher/pwconfig.sh to tell patchwatcher
about the ftp and pop3 accounts.

8. Create a directory 'shared' in the patchwatcher directory.
(If you're running a distributed patchwatcher. you'll need
to share this directory via nfs and/or cifs.)
Inside it, create a 'slave' directory; this is where jobs
that are queued for work will wait to be executed.

9. Run
  sh wine-slave.sh init
to prepare a wine tree for testing.

The next few steps will step you through
the process normally done automatically by
Patchwatcher so you can catch problems more easily.

10.  Try fetching patches by running 
  sh libpwdemo.sh receive
This should fetch patches from the pop3 mailbox and put
them in the shared/inbox directory.  Each patch series 
is called a job, and is placed in directories numbered
1 for the first patch series, 2 for the second, etc.
Verify that they contain good looking patches.

11. Once you have received some patches, assign them
to a build slave by running
  sh libpwdemo.sh assign_to slave

12. Run
  sh wine-slave.sh job 1
to test the first patch recieved above.
This takes the patch series in directory shared/slave/1,
tests it, moves the directory shared/slave/1 to shared/slave/done_1,
and creates a log in shared/slave/done_1/log.txt
describing the result of the test.

13. Run
  sh libpwdemo.sh move_finished
to move the completed jobs to shared/outbox.

14. Run
  sh libpwdemo.sh send_outbox
to upload the results of the job and send email.

(If something goes wrong, you can manually move
jobs between directories; that's often the easiest
way to retry a step.)

15. Verify that the first patch was properly
tested, email about it was sent to the
author and to you, and a page of results is
on the web site you told patchwatcher about.

Repeat steps 9 through 15 until you've debugged
your configuration.

16. Finally, in one window, run
  sh master.sh
and in another window, run
  sh wine-slave.sh run

This repeats all those steps automatically.  

Now sit back, let patchwatcher do its thing, and
be ready to catch it when it falls.

Known Problems

- the script that retrieves patches from the pop mailbox
  can't handle more than one outstanding patch series,
  so it gets stuck if anybody sends a partial patch series;
  until we fix this, you have to delete offending patches
  from the mailbox by hand

- really poor documentation :-)

