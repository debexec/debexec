newuidmap ${PID} 0 $(id -u) 1 1 $(cat /etc/subuid | sed -n "s/$(id -un):\([^:]*\):\(.*\)/\1 \2/p")
newgidmap ${PID} 0 $(id -g) 1 1 $(cat /etc/subgid | sed -n "s/$(id -gn):\([^:]*\):\(.*\)/\1 \2/p")
#echo "deny" > /proc/${PID}/setgroups
