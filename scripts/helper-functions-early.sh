find_in_list() {
    ITEM="$1"
    shift 1
    found=0
    for ENTRY in $@; do
        if [ "${ENTRY}" = "${ITEM}" ]; then
            found=1
            break
        fi
    done
    echo $found
}
