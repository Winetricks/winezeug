Patchwatcher - a distributed precommit testing system

=== History

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

=== Design

Patchwatcher calls a patch (or patch series) a 'job'.
Each job has a sequentially numbered directory.  
The first job received from the mailing list is 1, 
the second job is 2, etc.    Inside a job, patches
(if more than one) are also numbered sequentially.

Job directories live in named work queues which are just 
subdirectories of a directory called 'shared'.
Job directories get moved around from queue to queue as they
progress through their life cycle.

The main work queues, in the order that jobs visit them, are:
 'inbox' (for jobs that have just been received),
 'slave' (for jobs that have been assigned to a build slave),
 'outbox' (for jobs that were just finished), and
 'sent' (for jobs whose results have been emailed and uploaded).

(In the future, when we support multiple build slave computers,
there will be more than one 'slave' directory; we'll probably
name them 'slave1', 'slave2', etc. or something clever like
that.)

So if we receive a three-patch series followed by
a single patch, we would see files shared/inbox/1/[123].patch
and shared/inbox/2/1.patch.

When a patch is done being applied / built / tested,
even if it fails, a file 'log.txt' is created with
a summary of the errors, and files 'XXX.log' and 'XXX.err' are
created for each patch, showing the build/test log and
just the error messages.  A successful job is one
that has zero-length .err files and a log.txt that says
"Patchwatcher: OK" on the first line.

This architecture was chosen to make it as easy as
possible to quickly throw together patchwatcher systems
that use various kinds of build/test slaves.
The fact that jobs are directories makes it easy to
manually rerun jobs through whatever section of the
pipeline you're debugging at the moment.

An example patchwatcher system is provided, consisting
of master.sh and wine-slave.sh.
master.sh receives patches, assigns them
to the single build slave, gathers the results when
the build slave finishes them, and publishes the result.
wine-slave.sh runs the standard Wine build and conformance test
on each patch in the job, and resets its private build tree
before each new job.

More complex workflows are expected.  For instance, we might
send jobs out to MacOSX, Windows, Linux, and Solaris build
slaves simultanously; master.sh would then be responsible
for merging the results of the builds together once all were
finished.  (i.e. producing a single log.txt file saying how
many errors there were on each platform, with the URL of each
.log and .err file.)

We might also have several build slaves of the same type,
and a master.sh that balances the load across them.

=== Security

Essentially, there isn't any, so be very, very careful.
You could hurt yourself badly running Patchwatcher, so only do it
if you're sure you know what you're getting into.

Applying patches blindly from the raw patches list is a very dangerous
thing to do, since the patch could have malicious code in it.
Therefore, patchwatcher should be run in as walled-off an
environment as possible.  It should have its own user account,
ideally on a machine booted daily from a read-only disk,
and anything it touches should be considered suspect.
You should not use the computer that runs patchwatcher for
anything else, as it might be subverted, and install a 
keylogger or worse.

The FTP account for uploading results should also be as
powerless as possible.  It should not have shell access,
nor should it be able to write to any directory other than
the one it's supposed to.

=== Configuration

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

=== Known Problems

- the script that retrieves patches from the pop mailbox
  can't handle more than one outstanding patch series,
  so it gets stuck if anybody sends a partial patch series;
  until we fix this, you have to delete offending patches
  from the mailbox by hand

- really poor documentation :-)

=== Issue Tracking

Patchwatcher bugs are tracked at http://code.google.com/p/winezeug/issues

=== Related Applications

This is an old idea; we're not breaking any new ground here, but
better late than never!

http://buildbot.net is the most popular automated build system around.
It has some precommit test abilities, and Kai Blinn is working to
extend them so it can do what Patchwatcher does.  It would be nice
if we could drop Patchwatcher and just use Buildbot, but it'll
probably be a while before Kai catches up.  I like to think
of Patchwatcher as a rapid prototyping system for what Buildbot
should be doing in this area... but really I'm just too lazy to
work my way up the buildbot learning curve.

Hadoop has something similar, see 
http://developer.yahoo.net/blogs/hadoop/2007/12/if_it_hurts_automate_it_1.html

Drupal has something similar, see 
http://blog.boombatower.com/automated-patch-testing-(testing.drupal.org)-realized

Microsoft was doing something like this as early as 2001.  See
http://blogs.msdn.com/misampso/archive/2005/03/14/395374.aspx or
http://blogs.msdn.com/vcblog/archive/2006/11/02/gauntlet-a-peek-into-visual-c-development-practices.aspx

Many source code control systems have precommit hooks, and many
groups use them to run smoke tests, but those are 
usually very limited (e.g. < 30 seconds) because
they force the developer to wait.  Aegis had this
back in 1992.  See also
http://blogs.codehaus.org/people/vmassol/archives/000937_unbreakable_builds.html

gcc had a post-commit autotest back in 2000, see
http://web.archive.org/web/20010803160549/http://www.cygnus.com/~geoffk/gcc-regression/

Mozilla had a post-commit autotest called Tinderbox back in 1998.

=== Experimental Build Cluster

We're just getting the distributed build part of Patchwatcher going.
Here are some notes on how to set up a primitive cluster.
This is just an example; there are many ways to do this.

In these examples, the build master has hostname master, and
the build slaves have hostnames slave1, slave2, etc.
I will also assume that root login is not allowed, and that
the main user's account is named 'admin'; substitute your username
as needed.

The build slave machines must be dedicated, i.e. must not be used for
anything but running patchwatcher build slaves.  This is for your
protection; these machines may become compromised over time, since 
applying and testing incoming patches means running untrusted code.
You should consider using ghost or the like to save a known good
configuration and restore it periodically to wipe out any infection.

0. Reformat each machine and do a fresh installation of Ubuntu 8.10.

1. Arrange for stable IP addresses for all the machines in the cluster.
e.g. set your DHCP server on your local router to reserve their addresses.
I like to use a scheme where the master is .20, the first slave is .21, etc.

2. Install openssh-server on each machine so you can administer them
remotely via ssh/scp.  (This creates user sshd on each machine; you
want to end up with the same UID for each user on all machines, so
install packages in same order everywhere.)

3. Set up shared hostname and password database.

Since even Ubuntu 8.10 doesn't have an easy way
to set up kerberos+ldap yet, the easiest way to
achieve this is to cheat, and just set up identical
config files on each computer.

To do this, edit /etc/hosts by hand on master to have the
IP addresses of all the hosts in the cluster, then scp it to
each slave.  For instance, edit /etc/hosts to have a section
like this:

127.0.0.1	localhost.localdomain	localhost
192.168.1.20	master
192.168.1.21	slave1
192.168.1.22	slave2

Also create users patchmaster and patchslave, e.g.
  $ sudo adduser patchmaster
  $ sudo adduser patchslave

Then copy these files to the slaves, e.g.
  $ sudo bash
  # cd /root
  # umask 0077
  # tar -C /etc -f config.tar -c hosts passwd shadow group
  # scp config.tar admin@slave1:
  # scp config.tar admin@slave2:
  # exit
Then on each slave, do
  $ sudo tar -C /etc -f config-bak.tar -c hosts passwd shadow group
  $ sudo tar -C /etc -f config.tar -x 
  $ sudo mkdir /home/patchslave
  $ sudo chown patchslave.patchslave /home/patchslave
  $ rm config.tar
and reboot the slaves to make sure the admin and patchslave can log in properly,
then remove config-bak.tar.

4. Set up file sharing

Install NFS server on master, and NFS common on both slaves.
(See https://help.ubuntu.com/community/SettingUpNFSHowTo )

On the master, create a directory /home/pwshared owned by user patchmaster on all machines, e.g.

  $ sudo mkdir /home/pwshared; sudo chown patchmaster.patchmaster /home/pwshared

and create directories for each slave, e.g.

  $ sudo mkdir /home/pwshared/slave{1,2}
  $ sudo chown patchmaster.patchmaster /home/pwshared/slave{1,2}

On the master, export the slave directories.  i.e. edit /etc/exports and add
the lines

  /home/pwshared/slave1 slave1(rw,sync)
  /home/pwshared/slave2 slave2(rw,sync)

On each slave, mount its slave directory.  i.e. edit /etc/fstab and add a line like
  master:/home/pwshared/slave2 /home/pwshared/slave2 nfs
Then test the mount by doing
  $ sudo mount /home/pwshared/`hostname`
and make sure user patchslave can create a file in that directory,
and that it shows up in that directory on the master.

TODO: show how to solve permissions problem

4. Populate the patchmaster and patchslave accounts on the master

On the master, in both patchmaster and patchslave accounts, get a copy of 
the winezeug repository using the command

$ svn checkout http://winezeug.googlecode.com/svn/trunk/ winezeug

Then copy ~patchslave to both slave machines:
$ sudo su patchslave
$ cd /home
$ scp -a 

TODO: finish

=== end

