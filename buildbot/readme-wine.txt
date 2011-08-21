To get started with buildbot and wine, first do
  svn checkout http://winezeug.googlecode.com/svn/trunk/ winezeug
  cd winezeug/buildbot

Then try running
  sh winemaster.sh demo
to create a local buildbot master, and
  sh ../install-wine-deps.sh
  sh ../install-gecko.sh
  sh wineslave.sh demo
to create a local buildbot slave.

By default, the master watches for new git commits, and runs a single
build once the tree is stable.
If you also want to feed it patches from wine-patches, run
  sh winemaster.sh patchwatcher > patchwatcher.log 2>&1 &

Put your name and email address in ~/wineslave.dir/sandbox/slave/info/admin
and restart the slave, e.g.
  sh wineslave.sh stop start
and verify that it shows up properly in the builder list at http://localhost:8010

Once your slave is merrily building stuff, and most builds are green,
consider adding it to the winehq buildbot slave farm.  To do this,
contact dank@kegel.com with your IP address, he'll grant you access
and send you the buildmaster access info.  You can then start a fresh
slave as follows:
  sh wineslave.sh stop destroy
  sh wineslave.sh create BUILDMASTER SLAVENAME SLAVEPORT
  # Put your name and email address in ~/wineslave.dir/sandbox/slave/info/admin
  sh wineslave.sh start
Then verify that it shows up in the builder list at http://buildbot.kegel.com

You may want to set your slave's computer to automatically log in,
and tell Gnome to do
  cd ~/winezeug/buildbot
  sh wineslave.sh start
on startup.
(You can't start the slave from crontab, since it needs the desktop to run properly.)
