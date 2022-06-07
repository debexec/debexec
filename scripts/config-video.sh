GLX_LIBS="\
    /usr/lib/i386-linux-gnu/libGLX_nvidia.so.0 \
    /usr/lib/x86_64-linux-gnu/libGLX_nvidia.so.0 \
";

LIBS=""
for GLX_LIB in ${GLX_LIBS}; do
    DEPS=$(ldd "${GLX_LIB}" | sed -n 's|.* => \(.*libnvidia.*\) (.*)|\1|p')
    LIBS="${LIBS} ${GLX_LIB} ${DEPS}"
done
for LIB in ${LIBS}; do
    HOST_MD5=$(md5sum "${LIB}" | sed 's/ .*//')
    CONT_MD5=$(md5sum "${FAKEROOT}"/"${LIB}" | sed 's/ .*//')
    if [ "${HOST_MD5}" != "${CONT_MD5}" ]; then
        cp "${LIB}" "${FAKEROOT}"/"${LIB}"
    fi
done
