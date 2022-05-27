export DEBEXEC_TOGUI=$(mktemp --dry-run --tmpdir "debexec-togui.XXXXXXXXXX")
export DEBEXEC_FROMGUI=$(mktemp --dry-run --tmpdir "debexec-fromgui.XXXXXXXXXX")
export DEBEXEC_APTSTATUS=$(mktemp --dry-run --tmpdir "debexec-aptfifo.XXXXXXXXXX")
mkfifo "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}"
(\
    /usr/bin/env python3 "${DIR}"/debexec-gui.py "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}"; \
    cat "${DEBEXEC_TOGUI}" >/dev/null 2>/dev/null; \
    echo "DEBEXEC_GUI=0" > "${DEBEXEC_FROMGUI}"; \
) &
printf "DEBEXEC_LAUNCH=${DEBEXEC_LAUNCH}" > "${DEBEXEC_TOGUI}"
. "${DEBEXEC_FROMGUI}"; export DEBEXEC_GUI # DEBEXEC_GUI=[0|1]
if [ "${DEBEXEC_GUI}" -eq "0" ]; then
    cat "${DEBEXEC_APTSTATUS}" >/dev/null 2>/dev/null &
    rm "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}"
    touch "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}"
fi

# do not ever ask for input from the user
export DEBIAN_FRONTEND=noninteractive
