#/bin/bash
#
# This is an example of using haproxy.cfg to run a script

echo "Starting hello program"
while [ true ]
do
	echo "[$(date)] hello"
	sleep 5
done
