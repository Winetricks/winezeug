#!/bin/sh

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
     echo foo
  done

  # Then wait for no change for ten minutes 
  sleep 600
  while checked_git_pull
  do 
     sleep 600
  done
}

wait_for_update

