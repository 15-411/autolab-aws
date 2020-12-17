#!/bin/bash -e

tango_repo=15-411/Tango
autolab_repo=15-411/Autolab

logit () {
  echo "***SUMMARY*** $1"
  echo "$1" >> ~/.image-setup-summary.log
}

logit 'Starting script...'

sleep_time=120
if [ ! -z "$sleep_time" ]; then
  logit "Sleeping for $sleep_time seconds to allow for sufficient setup for Ubuntu..."
  sleep "$sleep_time"
fi

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

#0.1 Untarring archive
logit 'Untarring archive...'
tar xvf secret_files.tar.gz
rm secret_files.tar.gz

ssh_key_basename=$(basename -- "$SSH_KEY")
ssh_key_basename_no_extension=${ssh_key_basename%.*}
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
cat << "EOF" > ~/.bash_profile
source ~/.bashrc
export PATH=~/.rvm/gems/ruby-2.2.2/wrappers:$PATH
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
logit 'Writing AWS credentials...'
cat << EOF > ~ubuntu/.boto
[Credentials]
aws_access_key_id = $AWS_ACCESS_KEY
aws_secret_access_key = $AWS_SECRET_KEY
EOF

# Don't know where this directory comes from. :(
rmdir 1 || true

# Explain what to heck to do when you first SSH in to a new image.
cat << EOF > ~ubuntu/README
This is an instance that can become either a dev or a prod instance of Notolab. To choose, run one of "make_dev" or "make_prod". This will initialize stuff. Then, to start the webserver running, just run the startup script that is created by make_dev/make_prod.
EOF

# Create credentials to be imported into startup scripts.
logit 'Storing credentials as environment variables...'
cat << EOF > ~ubuntu/scripts/credentials.sh
export \\
  SSH_KEY=$SSH_KEY \\
  ssh_key_basename_no_extension=$ssh_key_basename_no_extension \\
  MAILER_USERNAME=$MAILER_USERNAME \\
  MAILER_PASSWORD=$MAILER_PASSWORD \\
  aws_region=us-east-1 \\
  email_for_errors=<FILL IN YOUR EMAIL!> \\
  s3_mysql_bucket=autolab-prod-mysql-backup \\
  s3_course_bucket=autolab-prod-course-backup \\
  ;
EOF

ln -s scripts/make_dev make_dev
ln -s scripts/make_prod make_prod
