#!/bin/sh

ARCHITECTURE="amd64"
DISTRIBUTION="unstable"
COMPONENTS="main non-free contrib"
MIRRORSITE="http://deb.debian.org/debian" # latest and greatest

if [ -f "${DEBEXEC_DIR}"/debexecrc ]; then
    . "${DEBEXEC_DIR}"/debexecrc
fi

case "${DEBEXEC_PERSIST}" in
    "") ;;
    debian-stable|debian-oldstable)
        echo "Unsupported persist option '${DEBEXEC_PERSIST}'!" 1>&2
        echo "You must use either a rolling development version (experimental, unstable, testing) or a release codename." 1>&2
        echo "The meaning of '${DEBEXEC_PERSIST}' changes over time, please see https://wiki.debian.org/DebianUnstable for details." 1>&2
        exit 1
        ;;
    # rolling development versions
    debian-experimental|debian-unstable|debian-testing)
        DISTRIBUTION=$(echo "$DEBEXEC_PERSIST" | sed 's/^debian-//')
        COMPONENTS="main non-free contrib"
        MIRRORSITE="http://deb.debian.org/debian" # latest and greatest
        ;;
    # releases by codename
    debian-buster|debian-bullseye|debian-bookworm)
        DISTRIBUTION=$(echo "$DEBEXEC_PERSIST" | sed 's/^debian-//')
        COMPONENTS="main non-free contrib"
        MIRRORSITE="http://deb.debian.org/debian" # latest and greatest
        ;;
    # unknown
    debian-*)
        echo "Unsupported persist option '${DEBEXEC_PERSIST}'!" 1>&2
        echo "This persist codename might be used for an official Debian upstream in the future." 1>&2
        exit 1
        ;;
esac
