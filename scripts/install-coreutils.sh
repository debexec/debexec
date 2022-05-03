send_gui "DEBEXEC_INSTALLCORE=1"

# configure minimal dpkg folders and files
mkdir -p /var/lib/dpkg/{info,updates}
touch /var/lib/dpkg/status

find_pattern() {
    DEBS=""
    for DEB in "$@"; do
        if [[ -f "${DEBPATH}"/${DEB}_*.deb ]]; then
            DEB=$(cd "${DEBPATH}"; ls ${DEB}_*.deb | sed 's/^\([^_]*\)_.*/\1/')
        fi
        DEBS="${DEBS} ${DEB}"
    done
    echo "${DEBS}"
}

# install the dependencies required by coreutils, dpkg, and dash
install_deps --and-package $(find_pattern gcc-*-base)

# note: these dependencies must be installed in a _very_ specific order and our dependency resolver
# is not smart enough to handle that yet
#install_deps --simultaneously dpkg
DEBS="libattr1 libacl1 libgcc1 libgcc-s1 libc6 libpcre2-* libpcre3 libselinux1 libzstd1 zlib1g liblzma5 libbz2-1.0 libgmp10"
#DEBS="libattr1 libc6 libgcc1 libpcre3 libacl1 libc6 libselinux1   libbz2-1.0 liblzma5 zlib1g"
DEBS=$(find_pattern ${DEBS})
dpkg -i $(add_deb_path ${DEBS})

# unpack the files from a few core packages so that we have what we need on the filesystem to switch
# over to using our own libraries from inside the chroot
dpkg --unpack $(add_deb_path \
    coreutils \
    dash \
    grep \
    sed \
    dpkg \
    tar \
)

# the mountpoint is now sufficiently configured that we can setup the path and switch over to using
# the libraries from inside the chroot
export PATH=/usr/bin:/bin:/usr/sbin:/REAL_ROOT/sbin:/REAL_ROOT/usr/bin:/REAL_ROOT/bin
unset LD_LIBRARY_PATH
mkdir -p /etc/alternatives /var/log /var/lib/dpkg/alternatives

# finish installing coreutils, dpkg, and dash
install_deps --and-package coreutils debianutils dpkg
install_deps dash
install_deps --and-package mawk dash

# less is needed for "pager" in dpkg (dpkg -l) and libcrypt1 is needed for some versions of perl-base:
install_deps --and-package \
    less \
    libcrypt1 \
;

# needed for actually installing anything with apt
install_deps --and-package \
    libc-bin \
    debconf \
    diffutils \
    findutils \
;
