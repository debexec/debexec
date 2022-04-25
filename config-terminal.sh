# label the terminal as being inside a chroot
echo "debexec" > /etc/debian_chroot

# install ncurses so that regular terminal behaviors act like expected
apt install --yes ncurses-term
