# copy files from the host (unless they already match)
for FILE in $@; do
    mkdir -p $(dirname "${FILE}" 2>/dev/null)
    HOST_MD5=$(md5sum /REAL_ROOT"${FILE}" 2>/dev/null | sed 's/ .*//')
    CONT_MD5=$(md5sum "${FILE}" 2>/dev/null | sed 's/ .*//')
    if [ "${HOST_MD5}" != "${CONT_MD5}" ]; then
        cp /REAL_ROOT"${FILE}" "${FILE}"
    fi
done
