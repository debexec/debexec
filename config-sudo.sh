# install the sudo utility and some missing pam files it needs
apt install --yes sudo libpam-runtime

# allow the user to use sudo and don't require a password to do so
chmod u+w /etc/sudoers
echo "${DEBEXEC_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod u-w /etc/sudoers

# install uidmap and configure all the appropriate permissions for the "root" user
chown -R 65535:65535 /usr/bin/sudo /etc/sudoers /etc/sudoers.d /usr/lib/sudo /usr/libexec/sudo /etc/sudo.conf 2>/dev/null
chmod u+s /usr/bin/sudo

if [ "${DEBEXEC_UIDMAP}" -eq "1" ]; then
    DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
    . /REAL_ROOT/"${DIR}"/config-preload.sh
fi
