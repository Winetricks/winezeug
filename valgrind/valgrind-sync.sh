#!/bin/sh
set -e
set -x

# We grep error messages, so make them all English
LANG=C

setup()
{
   # Unapply local patches before sync
   git diff > valgrind-sync-$$.patch
   patch -R -p1 < valgrind-sync-$$.patch
   cleaned=0
   trap cleanup 0 INT 
}

cleanup()
{
   # Reapply local patches after sync
   test $cleaned = 1 && exit
   patch -p1 < valgrind-sync-$$.patch
   status=$?
   cleaned=1

   case $status in
   0) exit 0 ;;
   *) echo "Patch failed"; exit 1
   esac
}

# Returns success if something was pulled
checked_git_pull()
{
  echo pulling
  git pull > git.log 2>&1
  cat git.log
  if grep -q "Already up-to-date." < git.log
  then
    return 1
  fi
  return 0
}

wait_for_update()
{
  # Wait until some change
  while ! checked_git_pull
  do
     sleep 600
  done

  # Then wait for no change for ten minutes 
  sleep 600
  while checked_git_pull
  do 
     sleep 600
  done
}

setup
wait_for_update
cleanup
