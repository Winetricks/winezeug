To get started with buildbot and wine, first do
  svn checkout http://winezeug.googlecode.com/svn/trunk/ winezeug
  cd winezeug/buildbot

Then try running
  sh winemaster.sh demo
to create a local buildbot master, and
  sh ../install-wine-deps.sh
  sh wineslave.sh demo
to create a local buildbot slave.

By default, the master watches for new git commits as well as
patches from wine-patches.  
(A single build is done per batch of git commits, but each patch 
in a patch series gets its own build.)

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

Tips
- All slaves need at least 1 GB of RAM.  More is better.
- General purpose buildslaves should have a CPU that is as fast or faster than
  an intel core 2 duo e8400 (i.e. scores 2400 or higher in
  http://www.cpubenchmark.net/cpu_list.php ) as well as a reasonable nvidia
  graphics card (e.g. a GeForce 8500 or later), should run the buildslave in
  the foreground on a logged in console, and should not be doing anything 
  else (not even web browsing).  
- Special purpose buildslaves (e.g. for alternate compilers or architectures)
  can be slower, can share the computer, and can run in the background from
  /etc/init.d or cron.
- If the second ccache'd build takes longer than 2 minutes on an i7
  or 6 minutes on an e7300, something's wrong; check ccache -s and make
  sure the hit rate is ok.  (It ought to be, now that wineslave.sh sets
  CCACHE_SLOPPINESS.)
- ext4 is 20% or so faster than ext3.  Make sure the buildbot is using
  that for the build directory and for ~/.ccache
- Heat can be a problem; try 
     apt-get install lm-sensors
     sensors-detect
     watch sensors
  and verify that your cpu isn't getting near the critical temperature during
  a build.
- Power saving measures may affect speed.
  Try "cpufreq-set -g performance -r" or "cpufreq-set -g conservative -r"
  and then verify that the setting took on all cores with cpufreq-info
  If it didn't, try setting it individually for each core with e.g.
  "for core in `seq 1 8`; do cpufreq-set -g performance -c$core; done"
