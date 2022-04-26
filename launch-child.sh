DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

unshare -Um "$@" &
PID=$!
UIDMAP="0 $(id -u) 1 1 $(cat /etc/subuid | sed -n "s/$(id -un):\([^:]*\):\(.*\)/\1 \2/p")"
GIDMAP="0 $(id -g) 1 1 $(cat /etc/subgid | sed -n "s/$(id -gn):\([^:]*\):\(.*\)/\1 \2/p")"
/bin/sh "${DIR}"/config-ids.sh "${PID}" "${UIDMAP}" "${GIDMAP}"
fg %1
wait ${PID}
