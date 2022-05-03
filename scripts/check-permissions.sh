DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. "${DIR}"/load-config.sh

DEBEXEC_ACCESS=""
if [ ! -z "${USENETWORK}" ] && [ "${USENETWORK}" != "no" ]; then
    SERVICE="Network/Internet Access"
    DEBEXEC_ACCESS="${DEBEXEC_ACCESS} $(printf "\t%s\n" "${SERVICE}")"
fi
DEBEXEC_ACCESS_CGROUP=0
if [ ! -z "${USECGROUP}" ] && [ "${USECGROUP}" != "yes" ]; then
    SERVICE="Process/Control Group Access"
    DEBEXEC_ACCESS="${DEBEXEC_ACCESS} $(printf "\t%s\n" "${SERVICE}")"
fi

if [ "${DEBEXEC_ACCESS}" != "" ] && [ "${DEBEXEC_GUI}" -eq "1" ]; then
    printf "DEBEXEC_ACCESS=${DEBEXEC_ACCESS}" > "${DEBEXEC_TOGUI}"
    . "${DEBEXEC_FROMGUI}" # ALLOW_ACCESS=[0|1]
elif [ "${DEBEXEC_ACCESS}" != "" ]; then
    echo "This application is requesting permissions to the following system services:" 1>&2
    echo "${DEBEXEC_ACCESS}" 1>&2
    printf "Grant access to these services? (Some applications may fail to function without granting access.) [yN] " 1>&2
    read ALLOW_ACCESS
fi
if [ ! -z "${ALLOW_ACCESS}" ]; then
    if [ "${ALLOW_ACCESS}" = "y" ] || [ "${ALLOW_ACCESS}" = "Y" ] || [ "${ALLOW_ACCESS}" = "yes" ]; then
        DEBEXEC_DIR="${DEBEXEC_DIR}" /bin/sh "${DIR}"/launch-flags.sh
    fi
fi
