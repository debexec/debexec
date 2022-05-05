#!/bin/sh

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEBEXEC_DIR="${DIR}"/../

DEBEXEC_LAUNCH=$(DEBEXEC_DIR="${DEBEXEC_DIR}" /bin/sh /"${DIR}"/config-launch.sh)

if [ "$1" != "--fakeroot" ]; then
    . "${DIR}"/launch-gui.sh
    DEBEXEC_PERMISSIONS=$(DEBEXEC_DIR="${DEBEXEC_DIR}" /bin/sh "${DIR}"/check-permissions.sh)
    if [ "$?" -ne "0" ]; then
        exit "$?"
    fi
    DEBEXEC_PERSIST=$(DEBEXEC_DIR="${DEBEXEC_DIR}" /bin/sh -c ". \"${DIR}\"/load-config.sh; echo \"\${DEBEXEC_PERSIST}\"")
    if [ "$?" -ne "0" ]; then
        exit "$?"
    elif [ "${DEBEXEC_PERSIST}" = "" ]; then
        FAKEROOT=$(mktemp -d --tmpdir "fakeroot.XXXXXXXXXX")
    else
        FAKEROOT="${HOME}"/.cache/debexec/"${DEBEXEC_PERSIST}"
        mkdir -p "${FAKEROOT}"
    fi
    export DEBEXEC_UIDMAP=$(/bin/sh "${DIR}"/use-uidmap.sh)
    /bin/sh -i "${DIR}"/launch-child.sh --mount -- "$0" --fakeroot "${FAKEROOT}" --username $(id -un) --userid $(id -u) --userid $(id -u) --groupid $(id -g) "$@"
    if [ "${DEBEXEC_PERSIST}" = "" ]; then
        rm -rf "${FAKEROOT}"
    fi
    rm "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTFIFO}" 2>/dev/null
    exit 0
fi

unset TMPDIR # do not use the external temporary directory

NOLAUNCH=0
ASROOT=0
SHIFT=1
while [ "${SHIFT}" -ne "0" ]; do
    case "$1" in
        --fakeroot) FAKEROOT="$2"; SHIFT=2;;
        --username) DEBEXEC_USER="$2"; SHIFT=2;;
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
CONFIGURED=$(cat "${FAKEROOT}"/var/cache/debexec/configured 2>/dev/null)

. "${DIR}"/query-debconf.sh
. "${DIR}"/config-root.sh
. /REAL_ROOT/"${DIR}"/helper-functions.sh
DEBEXEC_DIR=/REAL_ROOT/"${DEBEXEC_DIR}"
if [ "${CONFIGURED}" = "" ]; then
    . /REAL_ROOT/"${DIR}"/config-loader.sh
    . /REAL_ROOT/"${DIR}"/config-tmpbin.sh
    . /REAL_ROOT/"${DIR}"/config-permissions.sh # move ?
    . /REAL_ROOT/"${DIR}"/download-packages.sh
fi
if [ "${DEBEXEC_UIDMAP}" -eq "0" ]; then
    . /REAL_ROOT/"${DIR}"/config-preload.sh
fi
if [ "${CONFIGURED}" = "" ]; then
    . /REAL_ROOT/"${DIR}"/install-coreutils.sh
    . /REAL_ROOT/"${DIR}"/install-apt.sh
    . /REAL_ROOT/"${DIR}"/config-debconf.sh
    . /REAL_ROOT/"${DIR}"/config-terminal.sh
    . /REAL_ROOT/"${DIR}"/config-sudo.sh
fi

# call application-specific configuration for installing packages
(
    . /REAL_ROOT/"${DIR}"/load-config.sh
    if [ "${EXTRAPACKAGES}" != "" ]; then
        send_gui "DEBEXEC_INSTALLAPP=1"
        echo "destatus:0:0.0000:Updating apt package list..." >/REAL_ROOT/${DEBEXEC_APTFIFO}
        apt -o APT::Status-Fd=3 update 3>/REAL_ROOT/${DEBEXEC_APTFIFO}
        echo "destatus:1:0.0000:Installing packages..." >/REAL_ROOT/${DEBEXEC_APTFIFO}
        apt -o APT::Status-Fd=3 install --yes ${EXTRAPACKAGES} 3>/REAL_ROOT/${DEBEXEC_APTFIFO}
    fi
)

# select application to launch
if [ "${NOLAUNCH}" -eq "1" ]; then
    DEBEXEC_LAUNCH="${SHELL}"
fi

# store the user ID and group ID of the user for later use
mkdir -p /var/cache/debexec
echo "1" > /var/cache/debexec/configured
echo "${DEBEXEC_UID}" > /var/cache/debexec/uid
echo "${DEBEXEC_GID}" > /var/cache/debexec/gid

# let the gui know that we're all done
if [ "${DEBEXEC_GUI}" -eq "1" ]; then
    printf "DEBEXEC_EXIT=1" > "${DEBEXEC_TOGUI}"
    cat "${DEBEXEC_FROMGUI}" >/dev/null
fi

if [ "${ASROOT}" -eq "0" ]; then
    # revert to the regular user id:
    /bin/sh -i /REAL_ROOT/"${DIR}"/launch-child.sh ${DEBEXEC_PERMISSIONS} --revertuid -- "${DEBEXEC_LAUNCH}"
else
    # launch a root shell:
    "${DEBEXEC_LAUNCH}"
fi

# reset all permissions such that the unprivileged user can clean up the folder
for FILE in /*; do
    if [ "$(find_in_list ${FILE} /root /proc /sys /dev /home /mnt /media /REAL_ROOT)" -eq "1" ]; then
        continue
    fi
    chown -R root:root "${FILE}" 2>/dev/null
done
