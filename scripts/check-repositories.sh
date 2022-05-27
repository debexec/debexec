DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. "${DIR}"/load-config.sh

DEBEXEC_REPOSITORIES=""
if [ ! -z "${OTHERMIRROR}" ]; then
    OTHERMIRROR=$(export TMP="${DEBEXEC_DIR}"; export DEBEXEC_DIR="\${DEBEXEC_DIR}"; . "${TMP}"/debexecrc; echo "${OTHERMIRROR}")
    OLDIFS="${IFS}"
    IFS='|'
    for MIRROR in ${OTHERMIRROR}; do
        MIRRORNAME=$(echo "${MIRROR}" | sed 's/deb \(\[.*\] \|\)//' | sed -e 's|^.*://||' -e 's|/|_|g' -e 's| |_|g')
        if [ ! -f "${HOME}"/.cache/debexec/"${DEBEXEC_PERSIST}"/etc/apt/sources.list.d/${MIRRORNAME}.list ]; then
            MIRRORURL=$(echo "${MIRROR}" | sed 's/deb \(\[.*\] \|\)//')
            if [ ! -z "${DEBEXEC_REPOSITORIES}" ]; then
                DEBEXEC_REPOSITORIES="${DEBEXEC_REPOSITORIES}|"
            fi
            DEBEXEC_REPOSITORIES="${DEBEXEC_REPOSITORIES}${MIRRORURL}"
        fi
    done
    IFS="${OLDIFS}"
fi

if [ "${DEBEXEC_REPOSITORIES}" = "" ]; then
    exit 0
fi
if [ "${DEBEXEC_GUI}" -eq "1" ]; then
    printf "DEBEXEC_REPOSITORIES=${DEBEXEC_REPOSITORIES}" > "${DEBEXEC_TOGUI}"
    . "${DIR}"/read-gui.sh # ALLOW_ACCESS=[0|1]
else
    echo "This application is requesting to install software from the following repositories:" 1>&2
    echo "${DEBEXEC_REPOSITORIES}" | sed 's/|/\n/' 1>&2
    printf "Grant access to these repositories? (Installation will not proceed if access is not granted.) [yN] " 1>&2
    read ALLOW_ACCESS
fi
if [ ! -z "${ALLOW_ACCESS}" ]; then
    if [ "${ALLOW_ACCESS}" = "y" ] || [ "${ALLOW_ACCESS}" = "Y" ] || [ "${ALLOW_ACCESS}" = "yes" ]; then
        exit 0
    fi
fi
exit 1
