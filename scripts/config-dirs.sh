. "${DIR}"/load-config.sh

SPECIAL_DIRS="dev sys run/user proc" # NOTE: proc must be last for unmounting purposes
if is_set "${DEBEXEC_USEDISK}" ; then
    SPECIAL_DIRS="${SPECIAL_DIRS} home mnt media"
fi
echo "${SPECIAL_DIRS}"
