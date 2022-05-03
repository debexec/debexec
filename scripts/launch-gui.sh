export DEBEXEC_TOGUI=$(mktemp --dry-run --tmpdir "debexec-togui.XXXXXXXXXX")
export DEBEXEC_FROMGUI=$(mktemp --dry-run --tmpdir "debexec-fromgui.XXXXXXXXXX")
mkfifo "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}"
(/usr/bin/env python3 "${DIR}"/debexec-gui.py "${DEBEXEC_TOGUI}" "${DEBEXEC_FROMGUI}"; cat "${DEBEXEC_TOGUI}" >/dev/null 2>/dev/null; echo "DEBEXEC_GUI=0" > "${DEBEXEC_FROMGUI}") &
printf "DEBEXEC_LAUNCH=${DEBEXEC_LAUNCH}" > "${DEBEXEC_TOGUI}"
. "${DEBEXEC_FROMGUI}"; export DEBEXEC_GUI # DEBEXEC_GUI=[0|1]
