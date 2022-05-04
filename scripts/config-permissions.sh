# set up user and group permisssions
cp /REAL_ROOT/etc/passwd /REAL_ROOT/etc/group /etc/

# set the correct permissions on the temporary folder
chmod 1777 /tmp

# set the correct toplevel folder permissions to appease sudo (see folders in config-tmpbin.sh)
chmod 755 / /etc /bin /usr/bin

# configure a folder where we can store downloaded packages
mkdir -p "${DEBPATH}"

# allow DNS resolution to work
ln -s /REAL_ROOT$(realpath /etc/resolv.conf) /etc/resolv.conf
