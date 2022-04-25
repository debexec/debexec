mkdir -p /{bin,etc} /usr/bin
#for PROG in /bin/bash /bin/rm /bin/sed /bin/sleep /bin/sh /bin/tar /usr/bin/dpkg /usr/bin/dpkg-deb /usr/bin/dpkg-query /usr/bin/dpkg-split; do
for PROG in /bin/sh; do
    printf '#!%s /REAL_ROOT/bin/sh\nLD_LIBRARY_PATH=/REAL_ROOT/lib/x86_64-linux-gnu:/REAL_ROOT/usr/lib/x86_64-linux-gnu %s /REAL_ROOT%s "$@"' "${LD_LINUX}" "${LD_LINUX}" "${PROG}" > "${PROG}"
    chmod +x "${PROG}"
done
mkdir -p /tmp/bin
for PROG in /bin/bash /bin/rm /bin/sed /bin/sleep /bin/sh /bin/tar /usr/bin/dpkg /usr/bin/dpkg-deb /usr/bin/dpkg-query /usr/bin/dpkg-split; do
    BASENAME=$(basename "${PROG}")
    printf '#!%s /REAL_ROOT/bin/sh\nLD_LIBRARY_PATH=/REAL_ROOT/lib/x86_64-linux-gnu:/REAL_ROOT/usr/lib/x86_64-linux-gnu %s /REAL_ROOT%s "$@"' "${LD_LINUX}" "${LD_LINUX}" "${PROG}" > /tmp/bin/"${BASENAME}"
    chmod +x /tmp/bin/"${BASENAME}"
done
export PATH=/tmp/bin:${PATH}
