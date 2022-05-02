if [ "${CONFIGURED}" = "" ]; then
    mkdir -p "${FAKEROOT}/REAL_ROOT"
    for FILE in $(ls /); do ln -s "/${FILE}" "${FAKEROOT}/REAL_ROOT/${FILE}"; done
    for FILE in $(ls /); do ln -s "REAL_ROOT/${FILE}" "${FAKEROOT}/${FILE}"; done
fi
mount --bind "${FAKEROOT}" "${FAKEROOT}"
pivot_root "${FAKEROOT}" "${FAKEROOT}/REAL_ROOT"

LD_LINUX=$(realpath /REAL_ROOT/lib64/ld-linux-x86-64.so.2)

if [ "${CONFIGURED}" = "" ]; then
    # get rid of most of the temporary root system, only keep key files
    FILES=""
    for FILE in $(ls /); do
        if [ "${FILE}" = "dev" ] || [ "${FILE}" = "proc" ] || [ "${FILE}" = "home" ] || [ "${FILE}" = "mnt" ] || [ "${FILE}" = "media" ]; then
            continue
        fi
        FILES="${FILES} /${FILE}";
    done;
    rm ${FILES} 2>/dev/null;
fi
