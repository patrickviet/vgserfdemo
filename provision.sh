#!/bin/bash

# HOSTNAME
echo $1 > /etc/hostname
hostname $1

# APT IN GERMANY (update accordingly depending on where you are)
sed -ie s/us.archive.ubuntu.com/de.archive.ubuntu.com/g /etc/apt/sources.list

# No multiarch - faster!
rm -f /etc/dpkg/dpkg.cfg.d/multiarch

# No deb-src - faster!
sed -ie s/^deb-src/#deb-src/g /etc/apt/sources.list

apt-get update


# INSTALL CHEF
dpkg -l | grep chef

if [[ $? != 0 ]]
then
  curl https://www.opscode.com/chef/install.sh | bash
fi

mkdir -p /etc/chef
cp /vagrant/chef/solo.rb /etc/chef/solo.rb

chef-solo -o 'serf'
