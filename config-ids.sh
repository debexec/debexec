PID="$1"
UIDMAP="$2"
GIDMAP="$3"

newuidmap ${PID} ${UIDMAP}
newgidmap ${PID} ${GIDMAP}
#echo "deny" > /proc/${PID}/setgroups
