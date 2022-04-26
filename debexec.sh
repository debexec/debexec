#!/bin/bash

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$1" != "--fakeroot" ]; then
#if [ "$(id -u)" -ne "0" ]; then
    FAKEROOT=$(mktemp -d --tmpdir "fakeroot.XXXXXXXXXX")
    #"${DIR}"/mapuids "$0" "${FAKEROOT}"
    #unshare -Urm sh -c "exec \"${DIR}\"/mapuids \"$0\" \"${FAKEROOT}\""

    /bin/sh -i "${DIR}"/launch-child.sh "$0" --fakeroot "${FAKEROOT}" "$@"
    rm -rf "${FAKEROOT}"
    exit 0
fi

sleep 1 # give the ID mapping an opportunity to be configured

unset TMPDIR # do not use the external temporary directory

SHIFT=1
while [ "${SHIFT}" -ne "0" ]; do
    case "$1" in
        --fakeroot) FAKEROOT="$2"; SHIFT=2;;
        *) SHIFT=0;;
    esac
    shift ${SHIFT}
done
#echo $FAKEROOT

DEBPATH=/var/cache/debexec/aptcache
#DEBPATH=/var/cache/pbuilder/aptcache

. "${DIR}"/config-root.sh
. /REAL_ROOT/"${DIR}"/config-loader.sh
. /REAL_ROOT/"${DIR}"/config-tmpbin.sh
. /REAL_ROOT/"${DIR}"/config-permissions.sh # move ?
. /REAL_ROOT/"${DIR}"/helper-functions.sh
. /REAL_ROOT/"${DIR}"/install-coreutils.sh
. /REAL_ROOT/"${DIR}"/install-apt.sh
. /REAL_ROOT/"${DIR}"/config-terminal.sh
#. /REAL_ROOT/"${DIR}"/config-sudo.sh

# TODO: call application-specific configuration for installing packages

# revert to the regular user id:
#exec /REAL_ROOT/"${DIR}"/mapuids "${SHELL}"
# launch a root shell:
exec "${SHELL}"
