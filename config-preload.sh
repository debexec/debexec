# how to build:
#gcc -shared -fPIC debexec-preload.c -o debexec-preload.so -ldl

# let apt know that we're operating within a sandbox
mkdir -p /etc/apt/apt.conf.d
echo 'APT::Sandbox::Verify::IDs "false";' >> /etc/apt/apt.conf.d/99-sandbox

# hook ownership routines such that common sudo operations will complete successfully
if [ -f /REAL_ROOT/"${DIR}"/debexec-preload.so ]; then
    echo /REAL_ROOT/"${DIR}"/debexec-preload.so > /etc/ld.so.preload
fi
