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
if [ "${DEBEXEC_EXTRADEBS}" != "" ]; then
    I=0
    TOINSTALL=""
    for URL in ${DEBEXEC_EXTRADEBS}; do
        FILENAME="${DEBPATH}"/debexec-extradeb_${DEBEXEC_LAUNCH}_$I.deb
        OLDSUM=$(md5sum "${FILENAME}" 2>/dev/null)
        wget -O "${FILENAME}" -nc "${URL}"
        NEWSUM=$(md5sum "${FILENAME}" 2>/dev/null)
        if [ "${OLDSUM}" != "${NEWSUM}" ]; then
            TOINSTALL="${TOINSTALL} ${FILENAME}"
        fi
        I=$(($I + 1))
    done
    DEBEXEC_EXTRADEBS="${TOINSTALL}"
fi
if [ "${EXTRAPACKAGES}" != "" ] || [ "${DEBEXEC_EXTRADEBS}" != "" ]; then
    ARCHS=$(dpkg --print-architecture; dpkg --print-foreign-architectures)
    for PKG in ${EXTRAPACKAGES}; do
        ARCH=$(echo "${PKG}" | sed 's/[^:]*\(:\|$\)//')
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
    echo "destatus:0:0.0000:Updating apt package list..." >/REAL_ROOT/${DEBEXEC_APTSTATUS}
    apt -o APT::Status-Fd=3 update 3>/REAL_ROOT/${DEBEXEC_APTSTATUS}
    echo "destatus:1:0.0000:Installing packages..." >/REAL_ROOT/${DEBEXEC_APTSTATUS}
    if [ "${DEBEXEC_GUI}" -eq "1" ]; then
        APT_OPTIONS="${APT_OPTIONS} -o APT::Status-Fd=3 -o APT::Keep-Fds::=4 -o APT::Keep-Fds::=5"
        export DEBIAN_FRONTEND=passthrough
        #export DEBCONF_DEBUG=developer
        export DEBCONF_READFD=4
        export DEBCONF_WRITEFD=5
        export DEBIAN_PRIORITY="high"
    else
        export DEBIAN_FRONTEND=readline
    fi
    if [ ! -z "${DEBEXEC_TARGET}" ]; then
        APT_OPTIONS="${APT_OPTIONS} -t ${DEBEXEC_TARGET}"
    fi
    apt ${APT_OPTIONS} \
        install --yes ${EXTRAPACKAGES} ${DEBEXEC_EXTRADEBS} \
    3>/REAL_ROOT/${DEBEXEC_APTSTATUS} 4</REAL_ROOT/${DEBEXEC_APTREAD} 5>/REAL_ROOT/${DEBEXEC_APTWRITE}
fi
