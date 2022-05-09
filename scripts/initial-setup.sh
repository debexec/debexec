. "${DIR}"/launch-gui.sh
DEBEXEC_DIR="${DEBEXEC_DIR}" /bin/sh "${DIR}"/check-repositories.sh
RET="$?"
if [ "${RET}" -ne "0" ]; then
    exit "${RET}"
fi
DEBEXEC_PERMISSIONS=$(DEBEXEC_DIR="${DEBEXEC_DIR}" /bin/sh "${DIR}"/check-permissions.sh)
RET="$?"
if [ "${RET}" -ne "0" ]; then
    exit  "${RET}"
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
