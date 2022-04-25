# install the sudo utility
apt install --yes sudo

# allow the user to use sudo and don't require a password to do so
chmod u+w /etc/sudoers
echo "ehoover ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod u-w /etc/sudoers

# install uidmap and configure all the appropriate permissions for the "root" user
apt install --yes uidmap
echo "root:0:65536" > /etc/subuid
echo "root:0:65536" > /etc/subgid
chown -R 65535:65535 /usr/bin/sudo /etc/sudoers /etc/sudoers.d /usr/lib/sudo
chmod u+s /usr/bin/sudo

#newuidmap $PID 3087 0 1 1 1 1000 0 65535 1
#newdidmap $PID 3087 0 1 1 1 1000 0 65535 1
