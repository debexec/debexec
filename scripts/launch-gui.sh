DEBEXEC_TMPDIR=$(mktemp --directory --tmpdir "debexec.XXXXXXXXXX")
export DEBEXEC_TOGUI="${DEBEXEC_TMPDIR}"/togui
export DEBEXEC_FROMGUI="${DEBEXEC_TMPDIR}"/fromgui
export DEBEXEC_APTSTATUS="${DEBEXEC_TMPDIR}"/aptstatus
export DEBEXEC_APTREAD="${DEBEXEC_TMPDIR}"/aptread
export DEBEXEC_APTWRITE="${DEBEXEC_TMPDIR}"/aptwrite
mkfifo "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}" "${DEBEXEC_APTREAD}" "${DEBEXEC_APTWRITE}"
(\
    /usr/bin/env python3 "${DIR}"/debexec-gui.py "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}" "${DEBEXEC_APTREAD}" "${DEBEXEC_APTWRITE}"; \
    cat "${DEBEXEC_TOGUI}" >/dev/null 2>/dev/null; \
    echo "DEBEXEC_GUI=0" > "${DEBEXEC_FROMGUI}"; \
) &
printf "DEBEXEC_LAUNCH=${DEBEXEC_LAUNCH}" > "${DEBEXEC_TOGUI}"
. "${DEBEXEC_FROMGUI}"; export DEBEXEC_GUI # DEBEXEC_GUI=[0|1]
if [ "${DEBEXEC_GUI}" -eq "0" ]; then
    cat "${DEBEXEC_APTSTATUS}" >/dev/null 2>/dev/null &
    rm "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}" "${DEBEXEC_APTREAD}" "${DEBEXEC_APTWRITE}"
    touch "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}" "${DEBEXEC_APTSTATUS}" "${DEBEXEC_APTREAD}" "${DEBEXEC_APTWRITE}"
fi

# do not ever ask for input from the user
export DEBIAN_FRONTEND=noninteractive
