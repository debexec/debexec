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
    debian-unstable|debian-testing)
        APTKEYRINGS="${APTKEYRINGS} /usr/share/keyrings/debian-archive-keyring.gpg"
        DISTRIBUTION=$(echo "$DEBEXEC_PERSIST" | sed 's/^debian-//')
        COMPONENTS="main non-free contrib"
        MIRRORSITE="http://deb.debian.org/debian"
        ;;
    # unstable + additions
    debian-experimental)
        APTKEYRINGS="${APTKEYRINGS} /usr/share/keyrings/debian-archive-keyring.gpg"
        DISTRIBUTION=unstable
        COMPONENTS="main non-free contrib"
        MIRRORSITE="http://deb.debian.org/debian"
        DEBEXEC_TARGET=experimental
        if [ ! -z "${OTHERMIRROR}" ]; then
            OTHERMIRROR="${OTHERMIRROR}|"
        fi
        OTHERMIRROR="${OTHERMIRROR}deb http://deb.debian.org/debian experimental main"
        ;;
    # releases by codename
    debian-buster|debian-bullseye|debian-bookworm)
        APTKEYRINGS="${APTKEYRINGS} /usr/share/keyrings/debian-archive-keyring.gpg"
        DISTRIBUTION=$(echo "$DEBEXEC_PERSIST" | sed 's/^debian-//')
        COMPONENTS="main non-free contrib"
        MIRRORSITE="http://deb.debian.org/debian"
        ;;
    # releases by fixed version number
    debian-[0-9]*.[0-9]*)
        APTKEYRINGS="${APTKEYRINGS} /usr/share/keyrings/debian-archive-keyring.gpg"
        VERSION=$(echo "$DEBEXEC_PERSIST" | sed 's/^debian-//')
        MAJOR_VERSION=$(echo "$VERSION" | sed 's/\..*$//')
        if [ "${MAJOR_VERSION}" -eq "10" ]; then
            DISTRIBUTION="buster"
        elif [ "${MAJOR_VERSION}" -eq "11" ]; then
            DISTRIBUTION="bullseye"
        else
            echo "Unknown Debian major version '${VERSION}'!" 1>&2
        fi
        COMPONENTS="main non-free contrib"
        MIRRORSITE=$(/bin/sh "${DEBEXEC_DIR}"/scripts/get-archived-version.sh "${VERSION}")
        ;;
    # unknown
    debian-*)
        echo "Unsupported persist option '${DEBEXEC_PERSIST}'!" 1>&2
        echo "This persist codename might be used for an official Debian upstream in the future." 1>&2
        exit 1
        ;;
esac
