#!/bin/bash -e

# Source this script to get access to three string-manipulation functions
# useful in creating config files.

comment_out() {
  # comment_out prefix
  # Replace lines of the form:
  #  prefix......
  # with:
  #  # prefix......
  # (Taking input from standard in, and putting on standard out)
  # (The prefix will only be commented out if it forms a complete token on that line.)

  prefix=${1:?No prefix!}
  sed -e "s/^\([[:space:]]*\)$prefix\>/\1# $prefix/g"
}

uncomment_out () {
  # comment_out prefix
  # Replace lines of the form:
  #  # prefix......
  # with:
  #  prefix......
  # (Taking input from standard in, and putting on standard out)
  # (The prefix will only be uncommented if it forms a complete token on that line.)

  prefix=${1:?No prefix!}
  sed -e "s/^\([[:space:]]*\)#[[:space:]]*$prefix\>/\1$prefix/g"
}

replace_config() {
  # replace_config key value
  # Replace lines of the form:
  #  key: .......
  #  key = ............
  # with:
  #  key: value
  #  key = value
  # (Taking input from standard in, and putting on standard out)

  key=${1:?No key.}
  value=${2:?No value.}
  value=$(sed "s/\//\\\\\//g" <<< "$value")
  sed -e "s/^\([[:space:]]*\)$key: .*/\1$key: $value/g ; s/^\([[:space:]]*\)$key = .*/\1$key = $value/g"
}

export -f comment_out uncomment_out replace_config
