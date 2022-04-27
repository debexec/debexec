DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

. "${DIR}"/load-config.sh

if [ "${DEBEXEC_LAUNCH}" != "" ]; then
    echo "${DEBEXEC_LAUNCH}"
elif [ "${SHELL}" != "" ]; then
    echo "${SHELL}"
else
    echo "/bin/bash"
fi
