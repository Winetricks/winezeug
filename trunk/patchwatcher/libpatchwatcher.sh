# Library of shell functions to help construct a distributed patchwatcher
#
# These functions are meant to be used by several independent scripts,
# possibly running on different computers, possibly with different roles 
# running as different unix users for security purposes.
# A shared network filesystem is assumed.
#
# Conventions:
# Local variables are lowercase, globals are uppercase.
# Patch series live in numbered directories called jobs.
# Singleton patches not part of a series are considered a series of one patch.
# Each patch in a job is numbered 1.patch, 2.patch, etc.
# The result of patching/building/testing %d.patch is saved in %d.log
# The overall result of a job is saved in log.txt
# The last line of %d.log (or log.txt) indicates success or failure for that patch (or job, respectively)
# In particular, it must contain the string "patchwatcher:ok" on success.
#
# Jobs are first created in the 'inbox' directory,
# move to a directory named 'slave*' while being built,
# move to the 'outbox' directory when complete,
# and finally move to the 'sent' directory after their results are uploaded.
#
# To prevent half-baked jobs from being processed, we use a few rules:
# Jobs are named tmp.NNN during creation in inbox, then renamed atomically to NNN when ready to process
# Jobs are not moved from inbox to a slave directory unless their name starts with a digit
# Jobs are not moved from slave directories to outbox until they contain 
# a file 'log.txt', and that file is created atomically.

set -x
#----------------- Helper functions ------------------

# Call this function once at start of your script
# Assumes that $1/shared is the shared data directory for this patchwatcher
lpw_init()
{
    LPW_BIN=$1
    case "$LPW_BIN" in
    /.*) ;;
    *) LPW_BIN=`cd $LPW_BIN; pwd` ;;
    esac

    . "$LPW_BIN/pwconfig.sh"

    if ! test -d "$LPW_SHARED"
    then
        echo error: directory $LPW_SHARED does not exist
        exit 1
    fi
 
    LPW_INBOX="$LPW_SHARED/inbox"
    LPW_OUTBOX="$LPW_SHARED/outbox"
    LPW_SENT="$LPW_SHARED/sent"

    mkdir -p $LPW_INBOX/mimemail $LPW_OUTBOX $LPW_SENT
}

# Retrieve the number of the highest job in the system
# Result is placed in LPW_JOB
lpw_highest_job()
{
    dir=$LPW_SHARED

    # Directory might be in flight, so search twice
    LPW_JOB=0
    for try in 1 2 
    do
        job=`cd $dir; find . -name '[0-9]*' -type d -print | sed 's/.*\///' | sort -rn | head -n 1`
        test "$job" = "" && job=0
        test "$job" -gt "$LPW_JOB" && LPW_JOB=$job
    done
    return 0
}

# Retrieve the number of the next available job in the given directory
# Result is placed in LPW_JOB
# On failure, LPW_JOB is set to "", and function returns nonzero status
lpw_lowest_job()
{
    dir=$1
    if test "$dir" = ""
    then
        echo "lpw_lowest_job: sourcedir argument missing"
        exit 1
    fi
    dir=$LPW_SHARED/$dir
    if ! test -d $dir 
    then
        echo "lpw_lowest_job: no such directory $dir"
        exit 1
    fi

    job=`cd $dir; find . -name '[0-9]*' -type d -print | sed 's/^\.\///' | sort -n | head -n 1`
    LPW_JOB=$job
    test "$LPW_JOB" != ""
    return $?
}

#----------------- Action functions ------------------
# In rough order of workflow

# Find all finished jobs in inbox or slave*, and send to outbox
lpw_move_finished_jobs_to_outbox()
{
    for finished in `find $LPW_SHARED/inbox $LPW_SHARED/slave* -name log.txt -print 2>/dev/null | sed 's/\/log.txt//'`
    do
      job_basename=`basename $finished`
      mv "$finished" "$LPW_OUTBOX/`echo $job_basename | sed 's/done_//'`"
    done
}

# Call this to retrieve jobs from the pop3 mailbox specified in the
# environment variables used by get-patches2.pl
# Messages will be deleted from the mailbox as they are accepted for processing.
# Stillborn jobs are moved straight to outbox.
#
# Prerequisites:
# Must have Perl's Mail::POP3Client and MIME::Parser installed, e.g.
#    sudo apt-get install libmail-pop3client-perl libmime-perl
# Must set environment vars to point to a POP3 mailbox subscribed to the patches mailing list
#   PATCHWATCHER_USER=user@host.com
#   PATCHWATCHER_HOST=mail.host.com
#   PATCHWATCHER_PASSWORD=userpass 

lpw_receive_jobs()
{
    lpw_highest_job
    LPW_JOB=`expr $LPW_JOB + 1`
    (cd $LPW_INBOX; perl "$LPW_BIN/get-patches2.pl" $LPW_JOB) 
    lpw_move_finished_jobs_to_outbox
}

# Call this to move a job from inbox to the given directory
# On success, puts job number in $LPW_JOB, and returns with zero status
# On failure, returns with nonzero status
lpw_assign_job_to_slave()
{
    dest=$1
    if test "$dest" = ""
    then
        echo "lpw_assign_job_to_slave: destdir argument missing"
        exit 1
    fi
    dest=$LPW_SHARED/$dest
    if ! test -d $dest 
    then
        echo "lpw_assign_job_to_slave: no such directory $dest"
        exit 1
    fi

    lpw_lowest_job inbox
    if test "$LPW_JOB" = ""
    then
        return 1
    fi

    mv $LPW_INBOX/$LPW_JOB $dest/$LPW_JOB || return 1
    # Until permissions get sorted out, make world writable(!)
    # FIXME: sort out permissions; put both patchmaster and patchslave in a group
    chmod 777 $dest/$LPW_JOB

    return 0
}

# Summarize a completed job
lpw_summarize_job()
{
    dir=$1
    jobnum=$2

    # Create a log.txt file that just gives the most important details about what failed.

    # Did all the patches succeed?
    count=`ls $LPW_SHARED/$dir/$jobnum/*.log | wc -l`
    okcount=`grep -i "^patchwatcher:ok" $LPW_SHARED/$dir/$jobnum/*.log 2>/dev/null | wc -l`
    case $okcount in
        $count) 
            echo "Patchwatcher: OK, all $okcount patches in job built and passed regression test." 
            ;;
        *) 
	    echo "Patchwatcher: job FAILED, only $okcount out of $count patches succeeded" 
	    for err in $LPW_SHARED/$dir/$jobnum/*.err
	    do
                patch=`echo $err | sed 's/\.err/\.patch/'`
                patch_subject="`cat $patch | grep '^Subject:' | head -n 1 | sed 's/^Subject: //'`"
		file=`echo $err | sed 's,.*/,,;s,\..*,,'`
		if ! grep -qi "^patchwatcher:ok" "$err" 
		then
		    echo "------------------------------------------------------"
		    echo "Patchwatcher: patch $file of $count,"
		    echo "  $patch_subject"
                    echo "failed as follows:"
		    cat $err
		fi
	    done 
	    echo "------------------------------------------------------"
	    echo "Patchwatcher: end of log"
            ;;
    esac > "$LPW_SHARED/$dir/$jobnum/log_temp.txt"

    # mark the directory as done by changing its name so that it doesn't get
    # found by lpw_lowest_job any more
    mv "$LPW_SHARED/$dir/$jobnum" "$LPW_SHARED/$dir/done_$jobnum"

    # create the log.txt file after renaming the directory to avoid a race in
    # finding log.txt in the old directory
    mv "$LPW_SHARED/$dir/done_$jobnum/log_temp.txt" "$LPW_SHARED/$dir/done_$jobnum/log.txt"
}

# MAGIC HAPPENS

# Report the given job's results via email and web.
# The job must be in outbox and must already have a log.txt.
# Does not modify LPW_JOB or any other capitalized global.
#
# Prerequisites:
# Must have mailx installed and working, e.g.
#    sudo apt-get install mailx
#    sudo dpkg-reconfigure exim4-config
#
# Must set envionment vars to point to an ftp account:
#   PATCHWATCHER_FTP=ftp.host.com
# This script assumes that you have configured ftp (perhaps via ~/.netrc)
# with the username and password to allow the script to upload to the
# results directory at $PATCHWATCHER_FTP via ftp.
#
# Must set env vars to point to the web page results will appear:
#   PATCHWATCHER_URL=http://www.host.com/patchwatcher/results
# This should refer to the same directory as $PATCHWATCHER_FTP/results.

lpw_send_job()
{
    jobnum=$1
    job=$LPW_OUTBOX/$jobnum
    log=$job/log.txt

    if test "$jobnum" = ""
    then
        echo "lpw_send_job: jobnum argument missing"
        exit 1
    fi
    if ! test -f $log 
    then
        echo "lpw_send_job: no such file $log"
        exit 1
    fi

    # Retrieve sender from first patch file
    # Patch file is written by get-patches2.pl in a specific format,
    # always starts with an email header.
    patch1=$job/1.patch
    patch_sender="`cat $patch1 | grep '^From:' | head -n 1 | sed 's/^From: //;s/.*<//;s/>.*//'`"
    patch1_subject="`cat $patch1 | grep '^Subject:' | head -n 1 | sed 's/^Subject: //'`"

    # Retrieve status from log file
    status=`head -n 1 $log`

    # Retrieve number of patches in series
    patch_count=`ls $job/*.patch | wc -l`

    case $status in
    *[Pp]atchwatcher:" "[Oo][Kk]*|*[Pp]atchwatcher:[Oo][Kk]*) 
        # The patch series was successful, so email them to the filtered patch list.
        # TODO: parameterize destination
        i=1
        while test $i -le $patch_count
        do
            patch=$job/$i.patch
            patch_subject="`cat $patch | grep '^Subject:' | head -n 1 | sed 's/^Subject: //'`"
            mailx -s "${patch_sender}: $patch1_subject" $PATCHWATCHER_RESULT_EMAIL_ADDR < $patch 
            i=`expr $i + 1`
        done
        ;;
    *)   
        # The patch series was unsuccessful, so send an error message for each failed patch to the user.
        # TODO: parameterize destination better
        # TODO: parameterize message text better
        cat - $job/log.txt > /tmp/msg.dat.$$ <<_EOF_
EXPERIMENTAL VERSION 2 PLEASE IGNORE THIS MAIL

Hi!  This is the experimental automated patchwatcher thingy.

The latest sources were built and tested with your patch,
but it seems to have failed.
You can view the patch(es) and build log(s) at
  $PATCHWATCHER_URL/$jobnum

Here are the patches and associated errors:
_EOF_

        # FIXME: make it configurable whether to send mail to author
        #mailx -s "${status}: $patch1_subject" "$patch_sender" $PATCHWATCHER_FAIL_EMAIL_ADDR  < /tmp/msg.dat.$$
        mailx -s "${status}: $patch1_subject" $PATCHWATCHER_FAIL_EMAIL_ADDR  < /tmp/msg.dat.$$
        rm /tmp/msg.dat.$$
        ;;
    esac

    (cd $LPW_SHARED; perl $LPW_BIN/dashboard2.pl) > index.html
    ftp $PATCHWATCHER_FTP <<_EOF_
cd results2
put index.html
mkdir $jobnum
lcd $job
cd $jobnum
prompt
mput *.patch
mput *.log
mput log.txt
quit
_EOF_
}

# Send all finished jobs in outbox, and move them to sent
lpw_send_outbox()
{
    while lpw_lowest_job outbox
    do
        lpw_send_job $LPW_JOB
        mv $LPW_OUTBOX/$LPW_JOB $LPW_SENT/$LPW_JOB
    done
}

#----------------- Debugging functions ------------------

# Debugging tool to let you try out functions interactively
demo_shell()
{
    lpw_init `dirname $0`

    set -x
    case "$1" in
    "")
       set +x
       echo "usage: $0 cmd [arg]";  
       echo "helper cmds: lowest DIR, lowest_finished DIR, highest"
       echo "action cmds: receive, assign_to DIR, move_finished, send, send_outbox";;

    # Helper functions
    lowest)  
       lpw_lowest_job $2;  echo LPW_JOB is $LPW_JOB;;
    lowest_finished)
       lpw_lowest_finished_job $2;  echo LPW_JOB is $LPW_JOB;;
    highest) 
       lpw_highest_job;    echo LPW_JOB is $LPW_JOB;;

    # Action functions
    receive) 
       lpw_highest_job; before=$LPW_JOB; lpw_receive_jobs; lpw_highest_job; echo LPW_JOB was $before, is $LPW_JOB;;
    assign_to)   
       lpw_assign_job_to_slave $2;   echo LPW_JOB is $LPW_JOB;;
    move_finished)
       lpw_move_finished_jobs_to_outbox;;
    send)
       lpw_send_job $2;;
    send_outbox)
       lpw_send_outbox;;

    esac
}

