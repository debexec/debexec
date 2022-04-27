#!/bin/bash

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if [ "$1" != "--fakeroot" ]; then
#if [ "$(id -u)" -ne "0" ]; then
    FAKEROOT=$(mktemp -d --tmpdir "fakeroot.XXXXXXXXXX")
    #"${DIR}"/mapuids "$0" "${FAKEROOT}"
    #unshare -Urm sh -c "exec \"${DIR}\"/mapuids \"$0\" \"${FAKEROOT}\""

    /bin/sh -i "${DIR}"/launch-child.sh "$0" --fakeroot "${FAKEROOT}" --userid $(id -u) --groupid $(id -g) "$@"
    rm -rf "${FAKEROOT}"
    exit 0
fi

unset TMPDIR # do not use the external temporary directory

NOLAUNCH=0
ASROOT=0
SHIFT=1
while [ "${SHIFT}" -ne "0" ]; do
    case "$1" in
        --fakeroot) FAKEROOT="$2"; SHIFT=2;;
        --userid) DEBEXEC_UID="$2"; SHIFT=2;;
        --groupid) DEBEXEC_GID="$2"; SHIFT=2;;
        --as-root) ASROOT=1; SHIFT=1;;
        --no-launch) NOLAUNCH=1; SHIFT=1;;
        *) SHIFT=0;;
    esac
    shift ${SHIFT}
done
#echo $FAKEROOT

DEBPATH=/var/cache/debexec/aptcache

. "${DIR}"/query-debconf.sh
. "${DIR}"/config-root.sh
. /REAL_ROOT/"${DIR}"/config-loader.sh
. /REAL_ROOT/"${DIR}"/config-tmpbin.sh
. /REAL_ROOT/"${DIR}"/config-permissions.sh # move ?
. /REAL_ROOT/"${DIR}"/helper-functions.sh
. /REAL_ROOT/"${DIR}"/download-packages.sh
. /REAL_ROOT/"${DIR}"/install-coreutils.sh
. /REAL_ROOT/"${DIR}"/install-apt.sh
. /REAL_ROOT/"${DIR}"/config-debconf.sh
. /REAL_ROOT/"${DIR}"/config-terminal.sh
#. /REAL_ROOT/"${DIR}"/config-sudo.sh

# call application-specific configuration for installing packages
(
    . /REAL_ROOT/"${DIR}"/load-config.sh
    if [ "${EXTRAPACKAGES}" != "" ]; then
        apt install --yes ${EXTRAPACKAGES}
    fi
)

# select application to launch
DEBEXEC_LAUNCH=$(/bin/sh /REAL_ROOT/"${DIR}"/config-launch.sh)
if [ "${NOLAUNCH}" -eq "1" ]; then
    DEBEXEC_LAUNCH="${SHELL}"
fi

# store the user ID and group ID of the user for later use
mkdir -p /var/cache/debexec
echo "${DEBEXEC_UID}" > /var/cache/debexec/uid
echo "${DEBEXEC_GID}" > /var/cache/debexec/gid

if [ "${ASROOT}" -eq "0" ]; then
    # revert to the regular user id:
    exec /bin/sh -i /REAL_ROOT/"${DIR}"/launch-child.sh --revertuid "${DEBEXEC_LAUNCH}"
else
    # launch a root shell:
    exec "${DEBEXEC_LAUNCH}"
fi
