#!/bin/sh

install_deps --and-package apt

# configure the apt sources file
echo "deb [trusted=yes] file:/REAL_ROOT/${DEBPATH} ./" >> /etc/apt/sources.list
echo "deb [trusted=yes] http://snapshot.debian.org/archive/debian/20200801T030228Z stable main non-free contrib"  >> /etc/apt/sources.list

# set a "pin" to prefer the local copy of packages when they are available (TODO not needed?)
#cat << EOF > /etc/apt/preferences.d/99-prefer-local-packages
#Package: *
#Pin: origin ""
#Pin-Priority: 1001
#EOF

# keep downloaded packages so that it is easy to make a collection of them
echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >> /etc/apt/apt.conf.d/99-keep-downloads

# install common utilities that virtually everything will require (and were not already needed)
apt update
# * need to be installed first (core dependencies needed by other dependencies)
apt install --yes \
    grep \
;
# * rest of util-linux unlisted dependencies
apt install --yes \
    libterm-readline-gnu-perl \
    init-system-helpers \
;
# * dependencies are satisfied
apt install --yes \
    bash \
    sed \
    apt-utils \
    gzip \
    util-linux \
;
