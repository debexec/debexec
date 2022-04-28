#!/bin/sh

# cannot use uidmap if it is not available
if [ "$(which newuidmap)" = "" ]; then
    echo "0"
    exit 0
fi

# explicitly requested uidmap behavior
if [ ! -z "${DEBEXEC_UIDMAP}" ]; then
    echo "${DEBEXEC_UIDMAP}"
    exit 0
fi

# note: the use of uidmap is a complicated question that is a balance between security and the
# probability of things working.  for now, default to not using newuidmap.
echo "0"
