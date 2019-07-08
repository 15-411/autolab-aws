#!/bin/bash -e
# Run this script to get the webserver running.

# Print helpful error message if all three screens are already running.
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
  screen -S autolab -dm bash -c 'cd ~/Autolab ; sudo env PATH="\$PATH" bundle exec rails server -p 15411 -e production'
fi

echo "Everything is running, and once you have pointed the elastic IP for notolab.ml at"
echo "this instance, you should be able to access prod-notolab at this URL:"
echo "  https://notolab.ml"
echo "Once you have created and verified a user, you can promote yourself to admin"
echo "by running this command:"
echo "  ./promote_user your@email.goes.here"
