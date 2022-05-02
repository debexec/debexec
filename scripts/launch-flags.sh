DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. "${DIR}"/load-config.sh

if [ -z "${USENETWORK}" ] || [ "${USENETWORK}" = "no" ]; then
    printf "%s " "--net"
fi
if [ -z "${USECGROUP}" ] || [ "${USECGROUP}" = "yes" ]; then
    printf "%s " "--cgroup"
fi
