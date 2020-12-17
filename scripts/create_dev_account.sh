#!/bin/bash

# Since mailer doesn't work on dev notolab, this script can be run (without arguments)
# to create a developer user you can log in with at "Developer Login".

read -p "Email? (no single quotes) " email
read -p "First name? (no single quotes) " fn
read -p "Last name? (no single quotes) " ln

sqlite3 Autolab/db/db.sqlite3 << EOF
INSERT INTO users (email, first_name, last_name, confirmed_at, administrator) VALUES ('$email', '$fn', '$ln', 1, 1);
EOF

echo "User successfully created. You can now use Developer Login with that user at dev.notolab.cs.cmu.edu"
