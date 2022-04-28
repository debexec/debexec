# install the sudo utility and some missing pam files it needs
apt install --yes sudo libpam-runtime

# allow the user to use sudo and don't require a password to do so
chmod u+w /etc/sudoers
echo "${DEBEXEC_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod u-w /etc/sudoers

# install uidmap and configure all the appropriate permissions for the "root" user
chown -R 65535:65535 /usr/bin/sudo /etc/sudoers /etc/sudoers.d /usr/lib/sudo /usr/libexec/sudo /etc/sudo.conf 2>/dev/null
chmod u+s /usr/bin/sudo

# let apt know that we're operating within a sandbox
echo 'APT::Sandbox::Verify::IDs "false";' > /etc/apt/apt.conf.d/99-sandbox

# hook ownership routines such that common sudo operations will complete successfully
if [ -f /REAL_ROOT/"${DIR}"/debexec-preload.so ]; then
    echo /REAL_ROOT/"${DIR}"/debexec-preload.so > /etc/ld.so.preload
fi
# how to build:
#gcc -shared -fPIC hook-preload.c -o hook-preload.so -ldl
