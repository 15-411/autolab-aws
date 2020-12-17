#!/bin/bash -e
# This script gets the dev webserver running.

cd ~ubuntu

# Ensure the right number of screens are present.
scripts/screen_count.sh

already_running() {
  # Check if this pattern exists in the output of "screen -ls"
  screen -ls | grep "$1" >/dev/null 2>&1
}

if already_running redis; then
  echo "Redis already started; skipping."
else
  echo "Initializing redis server..."
  screen -S redis -dm redis-server
fi

if already_running tango; then
  echo "Tango already started; skipping."
else
  echo "Initializing Tango..."
  screen -S tango -dm bash -c 'cd ~/Tango ; concurrently -n jobManager,server "python jobManager.py" "python restful-tango/server.py"'
fi

if already_running autolab; then
  echo "Autolab already started; skipping."
else
  echo "Initializing Autolab..."
  #shellcheck disable=2016
  screen -S autolab -dm bash -c 'cd ~/Autolab ; sudo env PATH="$PATH" bundle exec rails s -p 80 -b 0.0.0.0'
fi

echo "Everything is running, and once you have pointed the elastic IP for dev.notolab.cs.cmu.edu at"
echo "this instance, you should be able to access dev-notolab at this URL:"
echo "  https://dev.notolab.cs.cmu.edu"
echo "You can run the (interactive) script ./create_dev_account to create an account you"
echo "can log into from the 'Developer Login' page."
