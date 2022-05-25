. "${DIR}"/load-config.sh

if [ "${OTHERMIRROR}" != "" ]; then
    OLDIFS="${IFS}"
    IFS='|'
    for MIRROR in ${OTHERMIRROR}; do
        MIRRORNAME=$(echo "${MIRROR}" | sed 's/deb \(\[.*\] \|\)//' | sed -e 's|^.*://||' -e 's|/|_|g' -e 's| |_|g')
        echo "${MIRROR}" > /etc/apt/sources.list.d/${MIRRORNAME}.list
    done
    IFS="${OLDIFS}"
fi
if [ "${EXTRAPACKAGES}" != "" ]; then
    if [ -f "${DEBEXEC_DIR}"/keyring.gpg ]; then
        cp "${DEBEXEC_DIR}"/keyring.gpg /etc/apt/trusted.gpg.d/debexec-${DEBEXEC_LAUNCH}.gpg
    fi
    ARCHS=$(dpkg --print-architecture; dpkg --print-foreign-architectures)
    for PKG in ${EXTRAPACKAGES}; do
        ARCH=$(echo "${PKG}" | sed 's/.*\(:\|$\)//')
        if [ -z "${ARCH}" ]; then
            continue
        fi
        found=$(find_in_list ${ARCH} ${ARCHS})
        if [ "${found}" -eq "1" ]; then
            continue
        fi
        dpkg --add-architecture "${ARCH}"
        ARCHS=$(dpkg --print-architecture; dpkg --print-foreign-architectures)
    done
    send_gui "DEBEXEC_INSTALLAPP=1"
    echo "destatus:0:0.0000:Updating apt package list..." >/REAL_ROOT/${DEBEXEC_APTFIFO}
    apt -o APT::Status-Fd=3 update 3>/REAL_ROOT/${DEBEXEC_APTFIFO}
    echo "destatus:1:0.0000:Installing packages..." >/REAL_ROOT/${DEBEXEC_APTFIFO}
    apt -o APT::Status-Fd=3 install --yes ${EXTRAPACKAGES} 3>/REAL_ROOT/${DEBEXEC_APTFIFO}
fi
