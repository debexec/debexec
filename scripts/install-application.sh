. "${DIR}"/load-config.sh

if [ "${OTHERMIRROR}" != "" ]; then
    OLDIFS="${IFS}"
    IFS='|'
    for MIRROR in ${OTHERMIRROR}; do
        MIRRORNAME=$(echo "${MIRROR}" | sed 's/deb \(\[.*\] \|\)//' | sed -e 's|^.*://||' -e 's|/|_|g' -e 's| |_|g')
        echo "MIRRORNAME: $MIRRORNAME" 1>&2
        echo "${MIRROR}" > /etc/apt/sources.list.d/${MIRRORNAME}.list
    done
    IFS="${OLDIFS}"
fi
if [ "${EXTRAPACKAGES}" != "" ]; then
    send_gui "DEBEXEC_INSTALLAPP=1"
    echo "destatus:0:0.0000:Updating apt package list..." >/REAL_ROOT/${DEBEXEC_APTFIFO}
    apt -o APT::Status-Fd=3 update 3>/REAL_ROOT/${DEBEXEC_APTFIFO}
    echo "destatus:1:0.0000:Installing packages..." >/REAL_ROOT/${DEBEXEC_APTFIFO}
    apt -o APT::Status-Fd=3 install --yes ${EXTRAPACKAGES} 3>/REAL_ROOT/${DEBEXEC_APTFIFO}
fi
