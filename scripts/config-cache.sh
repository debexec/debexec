# move the debian packages to the cache folder
mkdir -p /var/cache/debexec/aptcache/
if [ ! -z "${DEBEXEC_TMP}" ]; then
    mv "${DEBEXEC_TMP}"/*.deb /var/cache/debexec/aptcache/
fi
