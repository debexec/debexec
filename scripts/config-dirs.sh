. "${DIR}"/load-config.sh

SPECIAL_DIRS="dev proc sys run"
if is_set "${DEBEXEC_USEDISK}" ; then
    SPECIAL_DIRS="${SPECIAL_DIRS} home mnt media"
fi
echo "${SPECIAL_DIRS}"
