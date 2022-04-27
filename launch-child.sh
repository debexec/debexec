DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

REVERTUID=0
if [ "$1" = "--revertuid" ]; then
    REVERTUID=1
    USEPROC="--use-proc"
    DEBEXEC_UID=$(cat /var/cache/debexec/uid)
    DEBEXEC_GID=$(cat /var/cache/debexec/gid)
    shift 1
fi

ARGS="$@"
TRIGA=$(mktemp --tmpdir "debexec-trigA.XXXXXXXXXX")
TRIGB=$(mktemp --tmpdir "debexec-trigB.XXXXXXXXXX")
mkfifo "${TRIGA}" "${TRIGB}" 2>/dev/null
unshare -Um /bin/sh -c "echo '' > '${TRIGA}'; cat '${TRIGB}'; rm '${TRIGA}' '${TRIGB}'; ${ARGS}" &
PID=$!
cat "${TRIGA}"
if [ "${REVERTUID}" -eq "1" ]; then
    UIDMAP=$(printf "${DEBEXEC_UID} 0 1\n1 1 999\n0 65535 1\n")
    GIDMAP=$(printf "${DEBEXEC_GID} 0 1\n1 1 999\n0 65535 1\n")
else
    UIDMAP="0 $(id -u) 1 1 $(cat /etc/subuid | sed -n "s/$(id -un):\([^:]*\):\(.*\)/\1 \2/p")"
    GIDMAP="0 $(id -g) 1 1 $(cat /etc/subgid | sed -n "s/$(id -gn):\([^:]*\):\(.*\)/\1 \2/p")"
fi
/bin/sh "${DIR}"/config-ids.sh ${USEPROC} "${PID}" "${UIDMAP}" "${GIDMAP}"
echo "" > "${TRIGB}"
fg %1
wait ${PID}
