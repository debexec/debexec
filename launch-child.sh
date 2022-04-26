DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

REVERTUID=0
if [ "$1" = "--revertuid" ]; then
    REVERTUID=1
    USEPROC="--use-proc"
    DEBEXEC_UID="$2"
    DEBEXEC_GID="$3"
    shift 3
fi

ARGS="$@"
unshare -Um /bin/sh -c "sleep 1; ${ARGS}" &
PID=$!
if [ "${REVERTUID}" -eq "1" ]; then
    UIDMAP="${DEBEXEC_UID} 0 1"
    GIDMAP="${DEBEXEC_GID} 0 1"
else
    UIDMAP="0 $(id -u) 1 1 $(cat /etc/subuid | sed -n "s/$(id -un):\([^:]*\):\(.*\)/\1 \2/p")"
    GIDMAP="0 $(id -g) 1 1 $(cat /etc/subgid | sed -n "s/$(id -gn):\([^:]*\):\(.*\)/\1 \2/p")"
fi
/bin/sh "${DIR}"/config-ids.sh ${USEPROC} "${PID}" "${UIDMAP}" "${GIDMAP}"
fg %1
wait ${PID}
