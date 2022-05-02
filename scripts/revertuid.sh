#!/bin/sh

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

exec /bin/sh -i /REAL_ROOT/"${DIR}"/launch-child.sh --user --revertuid "${SHELL}"
