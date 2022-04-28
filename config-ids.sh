USEPROC=0
if [ "$1" = "--use-proc" ]; then
    USEPROC=1
    shift 1
fi
PID="$1"
UIDMAP="$2"
GIDMAP="$3"

if [ "${USEPROC}" -eq "1" ]; then
    echo "deny" > /proc/${PID}/setgroups
    echo "${UIDMAP}" > /proc/${PID}/uid_map
    echo "${GIDMAP}" > /proc/${PID}/gid_map
else
    newuidmap ${PID} ${UIDMAP}
    newgidmap ${PID} ${GIDMAP}
fi
#echo "deny" > /proc/${PID}/setgroups
