#!/bin/bash -e

tango_repo=CMU-15-411-F18/Tango
autolab_repo=CMU-15-411-F18/Autolab

logit () {
  echo "***SUMMARY*** $1"
  echo "$1" >> ~/.image-setup-summary.log
}

logit 'Starting script...'

# 0. Environment validation
logit 'Validating environment...'
if [ -z "$AWS_SECRET_KEY" ]; then
  echo "./setup.sh: Missing: AWS_SECRET_KEY"
  exit 1
elif [ -z "$AWS_ACCESS_KEY" ]; then
  echo "./setup.sh: Missing: AWS_ACCESS_KEY"
  exit 1
elif [ -z "$MAILER_USERNAME" ]; then
  echo "./setup.sh: Missing: MAILER_USERNAME"
  exit 1
elif [ -z "$MAILER_PASSWORD" ]; then
  echo "./setup.sh: Missing: MAILER_PASSWORD"
  exit 1
elif [ -z "$SSH_KEY" ]; then
  echo "./setup.sh: Missing: Environment variable for SSH_KEY location."
  exit 1
fi
chmod 400 "$SSH_KEY" # Set permissions correctly.

# 1. Upgrade apt-get and install packages.
logit 'Upgrading packages and installing software...'
sudo apt-get update
sudo apt-get -y upgrade
sudo apt-get -y install \
  gcc \
  libmysqlclient-dev \
  make \
  python-pip \
  ruby-mysql2 \
  software-properties-common \
  ;

# 1.2 Install "concurrently" package from node
logit 'Installing "concurrently" from Node...'
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g concurrently

# 1.3 Installing Redis
logit 'Installing Redis...'
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
rm redis-stable.tar.gz
make -C redis-stable
sudo make -C redis-stable install

# 1.4 Installing Ruby
logit 'Installing Ruby 2.2.2...'
# From https://rvm.io/rvm/install
sudo apt-add-repository -y ppa:rael-gc/rvm
sudo apt-get update
sudo apt-get -y install rvm
sudo usermod -aG rvm ubuntu
# shellcheck disable=SC1091
source /etc/profile.d/rvm.sh
sudo /usr/share/rvm/bin/rvm install ruby-2.2.2
sudo chown ubuntu:ubuntu -R ~/.rvm
cat << EOF > ~/.bash_profile
source ~/.bashrc
export PATH=~rvm/gems/ruby-2.2.2/wrappers:$PATH
EOF

# 2. Clone latest versions of Autolab and Tango repos.
logit 'Cloning Tango and Autolab...'
git clone "https://github.com/$tango_repo"
git clone "https://github.com/$autolab_repo"

# 2.1 Install pip requirements from Tango.
logit 'Installing pip dependencies...'
pip install --user -r Tango/requirements.txt

# 2.2 Install ruby requirements from Autolab.
logit 'Installing ruby dependencies...'
( cd ~/Autolab ; sudo env PATH="$PATH" bundle install )

# 3. Add AWS credentials to ~ubuntu/.boto
cat << EOF > ~ubuntu/.boto
[Credentials]
aws_access_key_id = $AWS_ACCESS_KEY
aws_secret_access_key = $AWS_SECRET_KEY
EOF

# Initialize useful script for use in both make_dev and make_prod.
replace_config=$(cat << 'EOF'
replace_config () {
  key=$1
  value=$2
  value=$(sed "s/\//\\\\\//g" <<< "$value")
  sed "s/#$key =/ $key =/g ; s/\\<$key = .*/$key = $value/g"
}
EOF
)

# Script for counting the number of screens.
screen_count=$(cat << "EOF"
screen_count=$(screen -ls | grep $'^\t' | wc -l)
if [ "$screen_count" != 0 ]; then
  echo "ERROR: startup script already run, so the screens are already started."
  echo "To see the running screens, run:"
  echo "  screen -ls"
  echo "You can enter the screens with:"
  echo "  screen -r autolab"
  echo "  screen -r tango"
  echo "  screen -r redis"
  echo "Once you are in the screen, you can detach (which does not kill the screen)"
  echo "  by running ^A + d (which is Cmd-A followed by d on Mac)."
  echo "To kill the screen you are attached to, run ^A + :kill (which is Cmd-A"
  echo "  followed by typing ':kill and then pressing enter.)"
  exit 1
fi
EOF
)

# Don't know where this directory comes from. :(
rmdir 1 || true

# Script for setting up dev-specific things.
cat << EOF > ~ubuntu/make_dev
#!/bin/bash -e

$replace_config

echo "Remember to add the SSH public keys of TAs to ~ubuntu/.ssh/authorized_keys"
echo "so that they can access the AWS private key $SSH_KEY for sshing into the"
echo "other running instances."

# Initialize autograde config template
< ~/Autolab/config/autogradeConfig.rb.template \\
  replace_config RESTFUL_HOST "'localhost'" |
  replace_config RESTFUL_PORT 3000 |
  replace_config RESTFUL_KEY "'test'" > ~/Autolab/config/autogradeConfig.rb

# Initialize devise for mailer.
< ~/Autolab/config/initializers/devise.rb.template \\
  replace_config config.secret_key "''" |
  replace_config config.mailer_sender "'creds@notolab.ml'" > ~/Autolab/config/initializers/devise.rb

# Initialize mailer
< ~/Autolab/config/environments/production.template.rb \\
  replace_config config.action_mailer.delivery_method :smtp |
  replace_config config.action_mailer.smtp_settings "{ address: 'email-smtp.us-east-1.amazonaws.com', port: 587, enable_starttls_auto: true, authentication: 'login', user_name: '$MAILER_USERNAME', password: '$MAILER_PASSWORD', domain: 'notolab.ml' }" > ~/Autolab/config/environments/production.rb

# Initialize config
< ~/Tango/config.template.py \\
  replace_config VMMS_NAME '"ec2SSH"' |
  replace_config CANCEL_TIMEOUT 30 |
  replace_config AUTODRIVER_LOGGING_TIME_ZONE "'America/New_York'" |
  replace_config AUTODRIVER_STREAM True |
  replace_config MAX_OUTPUT_FILE_SIZE '1000 * 1024' |
  replace_config KEEP_VM_AFTER_FAILURE True |
  replace_config MAX_POOL_SIZE 2 |
  replace_config POOL_SIZE_LOW_WATER_MARK 1 |
  replace_config POOL_ALLOC_INCREMENT 1 |
  replace_config MAX_CONCURRENT_JOBS 1 |
  replace_config EC2_REGION "'us-east-1'" |
  replace_config EC2_REGION_LONG "'US East (N. Virginia)'" |
  replace_config EC2_USER_NAME "'ubuntu'" |
  replace_config DEFAULT_AMI "'ami-0afd8be702c9b181b'" |
  replace_config DEFAULT_INST_TYPE "'r5.large'" |
  replace_config DEFAULT_SECURITY_GROUP "'15-411 Worker'" |
  replace_config SECURITY_KEY_PATH "'$SSH_KEY'" |
  replace_config SECURITY_KEY_NAME "'$(basename "$SSH_KEY")'" |
  replace_config TANGO_RESERVATION_ID "'1'" > ~/Tango/config.py

# DB and school settings require no changes
cp ~/Autolab/config/database.yml.template ~/Autolab/config/database.yml
cp ~/Autolab/config/school.yml.template ~/Autolab/config/school.yml

( cd ~/Autolab
  RAILS_ENV=development bundle exec rake db:setup
)

cat << "STARTUP" > ~ubuntu/startup.sh
#!/bin/bash -e
# Run this script to get the webserver running.

$screen_count

echo "Initializing redis server..."
screen -S redis -dm redis-server
echo "Initializing Tango..."
screen -S tango -dm bash -c 'cd ~/Tango ; concurrently -n jobManager,server "python jobManager.py" "python restful-tango/server.py"'
echo "Initializing Autolab..."
screen -S autolab -dm bash -c 'cd ~/Autolab ; sudo env PATH="\$PATH" bundle exec rails s -p 80 -b 0.0.0.0'
STARTUP
chmod +x ~ubuntu/startup.sh
echo 'Success :) Run ./startup.sh to start the web server.'
rm make_dev make_prod
EOF

# Script for setting up prod-specific things.
cat << EOF > ~ubuntu/make_prod
#!/bin/bash -e

$replace_config

sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y \\
  nginx \\
  python-certbot-nginx \\
  ;
sudo certbot --nginx

cat << "STARTUP" > ~ubuntu/startup.sh
#!/bin/bash -e
# Run this script to get the webserver running.

$screen_count

echo "Initializing redis server..."
screen -S redis -dm redis-server
echo "Initializing Tango..."
screen -S tango -dm bash -c 'cd ~/Tango ; concurrently -n jobManager,server "python jobManager.py" "python restful-tango/server.py"'
echo "Initializing Autolab..."
screen -S autolab -dm bash -c 'cd ~/Autolab ; sudo env PATH="\$PATH" bundle exec rails server -p 15411 -e production'
STARTUP
chmod +x ~ubuntu/startup.sh
echo 'Success :) Run ./startup.sh to start the web server.'
rm make_dev make_prod
EOF

chmod +x ~ubuntu/make_dev
chmod +x ~ubuntu/make_prod
