export LD_LIBRARY_PATH=/REAL_ROOT/lib/x86_64-linux-gnu:/REAL_ROOT/usr/lib/x86_64-linux-gnu
export PATH=/REAL_ROOT/sbin:/REAL_ROOT/usr/bin:/REAL_ROOT/bin

"${LD_LINUX}" /REAL_ROOT/bin/mkdir /lib64
"${LD_LINUX}" /REAL_ROOT/bin/ln -s "${LD_LINUX}" /lib64/ld-linux-x86-64.so.2
