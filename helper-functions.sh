add_deb_path() {
    DEBS=""
    for DEB in $@; do
        if [ -f ${DEBPATH}/${DEB} ]; then
            DEBS="${DEBS} /${DEBPATH}/${DEB}"
        elif [ -f ${DEBPATH}/${DEB}_*.deb ]; then
            DEBS="${DEBS} ${DEBPATH}/${DEB}_*.deb"
        else
            echo "warning: ${DEB} does not appear to exist at ${DEBPATH}/" 1>&2
        fi
    done
    echo "${DEBS}"
}

get_package_deps() {
    TYPE="$1"
    PACKAGE="$2"
    dpkg-deb --verbose -I "${PACKAGE}" 2>/dev/null | grep -E "${TYPE}" | tr -d "|," | sed "s/([^)]*)/()/g" | tr -d "()" | tr " " "\n" | grep -Ev "${TYPE}"
}

is_installed() {
    dpkg -l "$1" 2>/dev/null | grep "^ii" >/dev/null
}

find_in_list() {
    ITEM="$1"
    shift 1
    found=0
    for ENTRY in $@; do
        if [ "${ENTRY}" = "${ITEM}" ]; then
            found=1
            break
        fi
    done
    echo $found
}

get_deps() {
    TYPE="$1"
    NEW_PACKAGES="$2"
    PACKAGES=""
    LOOKUP="${NEW_PACKAGES}"
    while [ "${NEW_PACKAGES}" != "" ]; do
        NEW_PACKAGES=""
        TMP_PACKAGES=""
        for PKG in ${LOOKUP}; do
            TMP=$(get_package_deps "${TYPE}" $(add_deb_path ${PKG}))
            TMP_PACKAGES="${TMP_PACKAGES} ${TMP}"
        done
        
        for TMP_PACKAGE in ${TMP_PACKAGES}; do
            found=0
            for PACKAGE in ${PACKAGES} ${NEW_PACKAGES}; do
                if [ "${PACKAGE}" = "${TMP_PACKAGE}" ]; then
                    found=1
#echo "found $PACKAGE" 1>&2
                    break
                fi
            done
            if [ "${found}" -eq "1" ] || is_installed ${TMP_PACKAGE}; then
                continue
            fi
            NEW_PACKAGES="${NEW_PACKAGES} ${TMP_PACKAGE}"
        done
        PACKAGES="${PACKAGES} ${NEW_PACKAGES}"
        LOOKUP="${PACKAGES}"
    done
    echo $PACKAGES
}

install_deps() {
    SIMULTANEOUS=0
    if [ "$1" = "--simultaneously" ]; then
        SIMULTANEOUS=1
        shift 1
    fi
    AND_PACKAGE=0
    if [ "$1" = "--and-package" ]; then
        AND_PACKAGE=1
        shift 1
    fi
    PACKAGE="$@"
    
    # find the list of dependencies
    PACKAGES=$(get_deps 'Depends|Pre-Depends' "${PACKAGE}")
    PACKAGES="${PACKAGES}"
    if [ "${AND_PACKAGE}" -eq "1" ]; then
        PACKAGES="${PACKAGES} ${PACKAGE}"
    fi

    # find the list of pre-dependencies for all the dependencies
    TMP=$(get_deps 'Pre-Depends' "${PACKAGES}")
    PREPACKAGES=$(get_deps 'Depends|Pre-Depends' "${TMP}")
    if [ "${TMP}" != "" ]; then
        PREPACKAGES="${PREPACKAGES} ${TMP}"
    fi

    # eliminate any duplicate dependencies
    TMP=${PACKAGES}
    PACKAGES=""
    for PKG in ${TMP}; do
        found=$(find_in_list ${PKG} ${PREPACKAGES})
        if [ "${found}" -eq "0" ]; then
            PACKAGES="${PACKAGES} ${PKG}"
        fi
    done

    if [ "${SIMULTANEOUS}" -eq "1" ]; then
        dpkg -i $(add_deb_path ${PREPACKAGES} ${PACKAGES})
    else
        if [ "${PREPACKAGES}" != "" ]; then
            # install the pre-dependencies needed to get ready to install the package
            dpkg -i $(add_deb_path ${PREPACKAGES})
        fi
        if [ "${PACKAGES}" != "" ]; then
            # install package and all its dependencies
            dpkg -i $(add_deb_path ${PACKAGES})
        fi
    fi
}
