#!/bin/bash -e
# Run this program to promote the given user to an administrator of Autolab.
[ "$#" -eq 1 ] || {
  echo "Run with one argument: the email to promote to admin."
  exit 1
}
cd Autolab
sudo env PATH="$PATH" RAILS_ENV=production bundle exec rake "admin:promote_user[$1]"
