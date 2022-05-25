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

download_file() {
    TMPPATH="$1"
    URL="$2"
    DESTINATION="$3"
    wget -O "${TMPPATH}"/tmp "${URL}" 2>/dev/null || return 1
    mv "${TMPPATH}"/tmp "${DESTINATION}"
    return 0
}

get_release_file() {
    DEBPATH="$1"
    RELEASE_PATH=dists/${DISTRIBUTION}/Release
    if [ ! -f "${DEBPATH}"/${RELEASE_PATH} ]; then
        mkdir -p $(dirname "${DEBPATH}"/${RELEASE_PATH})
        download_file "${DEBPATH}" ${MIRRORSITE}/${RELEASE_PATH} "${DEBPATH}"/${RELEASE_PATH}
        download_file "${DEBPATH}" ${MIRRORSITE}/${RELEASE_PATH}.gpg "${DEBPATH}"/${RELEASE_PATH}.gpg
        for KEYRING in ${APTKEYRINGS}; do
            if [ -f "/REAL_ROOT/${KEYRING}" ]; then
                OPTIONS="${OPTIONS} --keyring /REAL_ROOT/${KEYRING}"
            fi
        done
        gpg --no-options ${OPTIONS} \
            --keyserver keyserver.ubuntu.com --keyserver-options auto-key-retrieve \
            --verify "${DEBPATH}"/${RELEASE_PATH}.gpg "${DEBPATH}"/${RELEASE_PATH} \
        || exit 1;
    fi
    echo "${DEBPATH}"/${RELEASE_PATH}
}

validate_packages() {
    DEBPATH="$1"
    PACKAGES_FILE="$2"
    if [ "$(which gpg)" = "" ]; then
        echo "WARNING: cannot validate repository keys if gpg is not installed!" 1>&2
        return 0
    fi
    RELEASE_FILE=$(get_release_file "${DEBPATH}") || exit 1
    REPOHASH=$(cat "${RELEASE_FILE}" | grep "${COMPONENT}/binary-${ARCHITECTURE}/Packages.gz" | head -n 1 | cut -d' ' -f2)
    FILEHASH=$(md5sum "${PACKAGES_FILE}" | cut -d' ' -f1)
    if [ "${REPOHASH}" != "${FILEHASH}" ]; then
        exit 1
    fi
}

get_package_list() {
    DEBPATH="$1"
    PACKAGE="$2"
    PACKAGES_PATH=dists/${DISTRIBUTION}/${COMPONENT}/binary-${ARCHITECTURE}/Packages
    if [ ! -f "${DEBPATH}"/${PACKAGES_PATH} ]; then
        mkdir -p $(dirname "${DEBPATH}"/${PACKAGES_PATH})
        wget -O "${DEBPATH}"/${PACKAGES_PATH}.gz ${MIRRORSITE}/${PACKAGES_PATH}.gz
        validate_packages "${DEBPATH}" "${DEBPATH}"/${PACKAGES_PATH}.gz # || exit 1
        gunzip --keep "${DEBPATH}"/${PACKAGES_PATH}.gz
    fi
    sed -n "/^Package: ${PACKAGE}\$/,/^\$/{p;/^\$/q}" "${DEBPATH}"/${PACKAGES_PATH}
}

validate_package() {
    REPOHASH="$1"
    PACKAGES_FILE="$2"
    FILEHASH=$(md5sum "${PACKAGES_FILE}" | cut -d' ' -f1)
    if [ "${REPOHASH}" != "${FILEHASH}" ]; then
        echo "Downloaded package does not match repository checksum, aborting." 1>&2
        exit 1
    fi
}

download_package() {
    DEBPATH="$1"
    PACKAGE="$2"
    (
        . "${DIR}"/../scripts/load-config.sh
        found=0
        for COMPONENT in ${COMPONENTS}; do
            PACKAGE_INFO=$(get_package_list "${DEBPATH}" "${PACKAGE}") || exit 1
            VERSION=$(echo "${PACKAGE_INFO}" | sed -n 's/Version: //p')
            ARCHITECTURE=$(echo "${PACKAGE_INFO}" | sed -n 's/Architecture: //p')
            SOURCE_PKG=$(echo "${PACKAGE_INFO}" | sed -n 's/Source: \([^ ]*\).*/\1/p')
            REPOHASH=$(echo "${PACKAGE_INFO}" | sed -n 's/MD5sum: \([^ ]*\).*/\1/p')
            if [ "${SOURCE_PKG}" = "" ]; then
                SOURCE_PKG=${PACKAGE}
            fi
            
            if [ "$(printf %.3s "${SOURCE_PKG}")" = "lib" ]; then
                P=$(printf %.4s "${SOURCE_PKG}")
            else
                P=$(printf %.1s "${SOURCE_PKG}")
            fi
            if [ "${VERSION}" = "" ]; then
                continue
            fi
            VERSION=$(echo "${VERSION}" | sed 's/[0-9]\+://')
            if [ -f "${DEBPATH}"/${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb ]; then
                found=1
                break
            fi
            URL="${MIRRORSITE}/pool/${COMPONENT}/${P}/${SOURCE_PKG}/${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb"
            DESTINATION="${DEBPATH}"/${PACKAGE}_${VERSION}_${ARCHITECTURE}.deb
            #echo "${URL}"
            download_file "${DEBPATH}" "${URL}" "${DESTINATION}" || continue
            validate_package "${REPOHASH}" "${DESTINATION}" || exit 1
            found=1
            break
        done
        if [ "${found}" -eq "0" ]; then
            echo "could not find ${PACKAGE}" 1>&2
        fi
    )
    return 0
}

send_gui() {
    if [ -z "${DEBEXEC_GUI}" ] || [ "${DEBEXEC_GUI}" -ne "1" ]; then return; fi
    printf "$1\n" > "${DEBEXEC_TOGUI}"
}

download_dependencies() {
    DEBPATH="$1"
    shift 1
    NEW_PACKAGES="$@"
    PACKAGES="${NEW_PACKAGES}"
    ALL_PACKAGES="${NEW_PACKAGES}"
    I=0
    while [ "${NEW_PACKAGES}" != "" ]; do
        NEW_PACKAGES=""
        for PACKAGE in ${PACKAGES}; do
            send_gui "DEBEXEC_DOWNLOADSTEPS=$(echo "${ALL_PACKAGES}" | wc -w)"
            send_gui "DEBEXEC_DOWNLOADSTEP=${I}"
            I=$((${I} + 1))
            if [ -f ${DEBPATH}/${PACKAGE}_*.deb ]; then
                continue
            fi
            echo "Downloading ${PACKAGE}..." 1>&2
            send_gui "DEBEXEC_DOWNLOAD=${PACKAGE}"
            download_package ${DEBPATH} ${PACKAGE} || exit 1
            TMP=$(get_deps --search-path 'Depends|Pre-Depends' ${PACKAGE} 2>/dev/null)
            if [ "${TMP}" != "" ]; then
                NEW_PACKAGES="${NEW_PACKAGES} ${TMP}"
                ALL_PACKAGES="${ALL_PACKAGES} ${TMP}"
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

realpath() {
    if [ -L "/REAL_ROOT$1" ]; then
        TARGET=$(readlink "/REAL_ROOT$1")
    else
        echo "$1"
        return
    fi
    if [ "$(printf %.1s "${TARGET}")" = "/" ]; then
        BASEDIR=''
    else
        BASEDIR=$(dirname "$1")
    fi
    OLDIFS="${IFS}"
    IFS='/'
    for DIR in ${TARGET}; do
        if [ "${DIR}" = "" ]; then
            continue
        fi
        IFS="${OLDIFS}"
        DIR_TARGET=$(realpath "${BASEDIR}/${DIR}")
        if [ "$(printf %.1s "${DIR_TARGET}")" = "/" ]; then
            BASEDIR="${DIR_TARGET}"
        else
            BASEDIR="${BASEDIR}/${DIR_TARGET}"
        fi
        IFS='/'
    done
    IFS="${OLDIFS}"
    echo "${BASEDIR}"
}
