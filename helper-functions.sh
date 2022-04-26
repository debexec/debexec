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
    if [ "$1" = "--search-path" ]; then
        DEB="$2"
        if [ -f ${DEBPATH}/${DEB} ]; then
            return 0
        elif [ -f ${DEBPATH}/${DEB}_*.deb ]; then
            return 0
        fi
        return 1
    fi
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
    SEARCH_PATH=""
    if [ "$1" = "--search-path" ]; then
        SEARCH_PATH="$1"
        shift 1
    fi
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
            if [ "${found}" -eq "1" ] || is_installed ${SEARCH_PATH} ${TMP_PACKAGE}; then
                continue
            fi
            NEW_PACKAGES="${NEW_PACKAGES} ${TMP_PACKAGE}"
        done
        PACKAGES="${PACKAGES} ${NEW_PACKAGES}"
        LOOKUP="${PACKAGES}"
    done
    echo $PACKAGES
}

get_package_list() {
    DEBPATH="$1"
    PACKAGES_PATH=dists/${DISTRIBUTION}/${COMPONENT}/binary-${ARCHITECTURE}/Packages.gz
    if [ ! -f "${DEBPATH}"/${PACKAGES_PATH} ]; then
        mkdir -p $(dirname "${DEBPATH}"/${PACKAGES_PATH})
        wget -O - ${MIRRORSITE}/${PACKAGES_PATH} | gunzip > "${DEBPATH}"/${PACKAGES_PATH}
    fi
    cat "${DEBPATH}"/${PACKAGES_PATH}
}

download_package() {
    DEBPATH="$1"
    PACKAGE="$2"
    (
        . "${DIR}"/load-config.sh
        found=0
        for COMPONENT in ${COMPONENTS}; do
            PACKAGE_INFO=$(get_package_list "${DEBPATH}" | grep -A10 "^Package: ${PACKAGE}\$")
            VERSION=$(echo "${PACKAGE_INFO}" | sed -n 's/Version: //p')
            ARCHITECTURE=$(echo "${PACKAGE_INFO}" | sed -n 's/Architecture: //p')
            SOURCE_PKG=$(echo "${PACKAGE_INFO}" | sed -n 's/Source: \([^ ]*\).*/\1/p')
            if [ "${SOURCE_PKG}" = "" ]; then
                SOURCE_PKG=${PACKAGE}
            fi
            
            if [ "${SOURCE_PKG:0:3}" = "lib" ]; then
                P=${SOURCE_PKG:0:4}
            else
                P=${SOURCE_PKG:0:1}
            fi
            if [ "${VERSION}" = "" ]; then
                continue
            fi
            VERSION=$(echo "${VERSION}" | sed 's/[0-9]\+://')
            if [ -f "${DEBPATH}"/${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb ]; then
                found=1
                break
            fi
            #echo "${MIRRORSITE}/pool/${COMPONENT}/${P}/${SOURCE_PKG}/${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb"
            wget -O "${DEBPATH}"/tmp ${MIRRORSITE}/pool/${COMPONENT}/${P}/${SOURCE_PKG}/${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb 2>/dev/null || continue
            mv "${DEBPATH}"/tmp "${DEBPATH}"/${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb
            found=1
            break
        done
        if [ "${found}" -eq "0" ]; then
            echo "could not find ${PACKAGE}" 1>&2
        fi
    )
}

download_dependencies() {
    DEBPATH="$1"
    shift 1
    NEW_PACKAGES="$@"
    PACKAGES="${NEW_PACKAGES}"
    while [ "${NEW_PACKAGES}" != "" ]; do
        NEW_PACKAGES=""
        for PACKAGE in ${PACKAGES}; do
            if [ -f ${DEBPATH}/${PACKAGE}_*.deb ]; then
                continue
            fi
            echo "Downloading ${PACKAGE}..." 1>&2
            download_package ${DEBPATH} ${PACKAGE}
            TMP=$(get_deps --search-path 'Depends|Pre-Depends' ${PACKAGE} 2>/dev/null)
            if [ "${TMP}" != "" ]; then
                NEW_PACKAGES="${NEW_PACKAGES} ${TMP}"
            fi
        done
        PACKAGES="${NEW_PACKAGES}"
    done
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
