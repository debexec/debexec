mv /bin/tar /bin/tar.real
cat - > /bin/tar <<EOF
#!/bin/sh

echo "\$@" >>/REAL_ROOT/home/ehoover/fakeroot/log
/bin/tar.real --owner 0 --group 0 --no-same-owner --no-same-permissions "\$@"
EOF
chmod +x /bin/tar
