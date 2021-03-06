# set up critical directories
mkdir -p /etc /bin /usr/bin /run
mkdir -p /home/${DEBEXEC_USER}/.gnupg # required by gpg
ln -s /REAL_ROOT/usr/bin/dirmngr /usr/bin/dirmngr # required by gpg
ln -s /REAL_ROOT/usr/bin/gpg-agent /usr/bin/gpg-agent # required by gpg

REALSHELL="/REAL_ROOT$(realpath /bin/sh)"
for PROG in /bin/sh; do
    REALPROG="/REAL_ROOT$(realpath ${PROG})"
    printf '#!%s %s\nLD_LIBRARY_PATH=/REAL_ROOT/lib/x86_64-linux-gnu:/REAL_ROOT/usr/lib/x86_64-linux-gnu %s %s "$@"' "${LD_LINUX}" "${REALSHELL}" "${LD_LINUX}" "${REALPROG}" > "${PROG}"
    chmod +x "${PROG}"
done
for PROG in /bin/bash /bin/rm /bin/sed /bin/sleep /bin/sh /bin/tar /usr/bin/dpkg /usr/bin/dpkg-deb /usr/bin/dpkg-query /usr/bin/dpkg-split; do
    BASENAME=$(basename "${PROG}")
    printf '#!%s %s\nLD_LIBRARY_PATH=/REAL_ROOT/lib/x86_64-linux-gnu:/REAL_ROOT/usr/lib/x86_64-linux-gnu %s /REAL_ROOT%s "$@"' "${LD_LINUX}" "${REALSHELL}" "${LD_LINUX}" "${PROG}" > /tmp/bin/"${BASENAME}"
    chmod +x /tmp/bin/"${BASENAME}"
done
export PATH=/tmp/bin:${PATH}
