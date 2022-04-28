#!/bin/sh

ARCHITECTURE="amd64"
DISTRIBUTION="unstable"
COMPONENTS="main non-free contrib"
MIRRORSITE="http://deb.debian.org/debian" # latest and greatest

if [ -f "${DEBEXEC_DIR}"/debexecrc ]; then
    . "${DEBEXEC_DIR}"/debexecrc
fi
