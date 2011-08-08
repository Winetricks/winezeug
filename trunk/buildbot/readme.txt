Buildbot has been mature enough to use for some time.
Wine could probably benefit from running a buildbot.

Buildbot has good documentation, and a good tutorial.
Anyone who wants to play with it should read them through
and do the examples, then slowly mutate the example config
until it does what one wants.

To make this a bit easier, I wrote buildbot-tutorial.sh,
which is exactly the buildbot tutorial, with each step
turned into a shell function.  You can set up the tutorial
server with the single command
   sh buildbot-tutorial.sh all
but one should really do the individual steps.

To turn the example server into a wine buildbot, copy
master.cfg from here into /home/dank/tmp/buildbot/sandbox/master/master.cfg
and restart the server.  The buildbot will then do a build every time
Alexandre commits a run of changes; you can also force a run by going to
http://localhost:8010/builders/runtests
typing in your name, and clicking 'force build'.

