# set up critical directories
mkdir -p /{bin,etc} /usr/bin /run
ln -s /REAL_ROOT/run/user /run/user # required by dbus

REALSHELL="/REAL_ROOT$(realpath /REAL_ROOT/bin/sh | sed 's/REAL_ROOT//')"
for PROG in /bin/sh; do
    REALPROG="/REAL_ROOT$(realpath /REAL_ROOT${PROG} | sed 's/REAL_ROOT//')"
    printf '#!%s %s\nLD_LIBRARY_PATH=/REAL_ROOT/lib/x86_64-linux-gnu:/REAL_ROOT/usr/lib/x86_64-linux-gnu %s %s "$@"' "${LD_LINUX}" "${REALSHELL}" "${LD_LINUX}" "${REALPROG}" > "${PROG}"
    chmod +x "${PROG}"
done
mkdir -p /tmp/bin
for PROG in /bin/bash /bin/rm /bin/sed /bin/sleep /bin/sh /bin/tar /usr/bin/dpkg /usr/bin/dpkg-deb /usr/bin/dpkg-query /usr/bin/dpkg-split; do
    BASENAME=$(basename "${PROG}")
    printf '#!%s %s\nLD_LIBRARY_PATH=/REAL_ROOT/lib/x86_64-linux-gnu:/REAL_ROOT/usr/lib/x86_64-linux-gnu %s /REAL_ROOT%s "$@"' "${LD_LINUX}" "${REALSHELL}" "${LD_LINUX}" "${PROG}" > /tmp/bin/"${BASENAME}"
    chmod +x /tmp/bin/"${BASENAME}"
done
export PATH=/tmp/bin:${PATH}
