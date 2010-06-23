#!/bin/sh
set -e
set -x

# We grep error messages, so make them all English
LANG=C

setup()
{
   # Unapply local patches before sync
   git diff > yagmark-sync-$$.patch
   patch -R -p1 < yagmark-sync-$$.patch
   cleaned=0
   trap cleanup 0 INT 
}

cleanup()
{
   # Reapply local patches after sync
   test $cleaned = 1 && exit
   patch -p1 < yagmark-sync-$$.patch
   status=$?
   cleaned=1

    if test -f sync-git.log
    then
       if grep fatal: sync-git.log
       then
	  echo sync failed
	  exit 1
       fi
    fi

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
  git show | head -n 1 > rev1
  while true
  do
    checked_git_pull || true
    git show | head -n 1 > rev2
    if grep commit rev1 && grep commit rev2 && ! cmp rev1 rev2
    then
     break
    fi
    sleep 600
  done

  # Then wait for no change for ten minutes 
  sleep 600
  while checked_git_pull
  do 
     sleep 600
  done
}

rm -rf git.log
setup
case "$1" in
"") wait_for_update ;;
*) git reset --hard $1 > sync-git.log 2>&1 ; cat sync-git.log ;; 
esac
cleanup
