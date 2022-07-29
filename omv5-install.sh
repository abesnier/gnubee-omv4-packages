# Quick and dirty install script for OMV5 on the GnuBee (or any Debian buster distro as a matter of fact).
# Just make sure you don't already have a /git directory, as it will be purged...
# download this, and either sudo bash ./omv5-install.sh or chmod +x omv5-install.sh && sudo ./omv5-install.sh
# No guarantee what so ever, but it repeatedly produced a working machine for me during testing.
# https://groups.google.com/g/gnubee
# Github: https://github.com/abesnier/ 

#!/bin/bash -x

rm  /etc/apt/sources.list.d/*.list
# quick refresh of the system, and install some dependencies
apt update && apt upgrade -y && apt install git wget xsltproc php-dev libpam-dev quilt devscripts unzip debhelper build-essential --no-install-recommends -y
rm -rf /git
# create folder for git, use another one if you already have on
mkdir /git 
cd /git 
# clone the repos
# git clone https://github.com/saltstack/salt-bootstrap.git --d
git clone https://github.com/openmediavault/openmediavault.git --depth=1 --branch=5.x 
cd openmediavault 
git clone https://github.com/openmediavault/wsdd.git --depth=1 
# install salt - this way, the package is not managed by apt, so a little will be required down the line
# cd /git/saltstack
# sh bootstrap-salt.sh -r -P git master
# build wsdd
cd /git/openmediavault/wsdd 
debuild -b -uc -us 
# build libjs-extjs6
cd /git/openmediavault/deb/sources 
wget -c http://cdn.sencha.com/ext/gpl/ext-6.2.0-gpl.zip 
cd ../libjs-extjs6 
debuild -b -uc -us 
#build php-pam
cd ../php-pam 
debuild -b -uc -us 
# do not build omv yet, tweak required
# we just need to not make salt a dependency of OMV, as it is already installed
# cd ../openmediavault/debian
# sed -i 's/salt-minion (>= 3003),//g' control
# build omv
cd ..
make clean binary 
# make a local directory for a local repository
mkdir /var/local/deb-repo 
cp `find /git -name '*.deb'` /var/local/deb-repo 
cd /var/local/deb-repo 
wget --no-check-certificate https://raw.githubusercontent.com/abesnier/gnubee-omv4-packages/master/salt-minion_3003%2Bds-1_all.deb 
wget --no-check-certificate https://raw.githubusercontent.com/abesnier/gnubee-omv4-packages/master/salt-common_3003%2Bds-1_all.deb 
bash -c 'dpkg-scanpackages . | gzip > Packages.gz' 
echo "deb [trusted=yes] file:/var/local/deb-repo/ ./" | sudo tee /etc/apt/sources.list.d/localrepo.list 
echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee /etc/apt/sources.list.d/backports.list 
# install openmediavault
apt update && apt install openmediavault -y
omv-confdbadm populate 
omv-salt deploy run nginx 
omv-salt deploy run phpfpm
