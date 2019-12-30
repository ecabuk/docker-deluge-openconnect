#!/bin/bash

DELUGE_PID=$(supervisorctl pid deluge)

if [[ ${DELUGE_PID} == 0 ]]; then
	>&2 echo "Deluge is not running!"
	exit 1;
fi

# Wait until deluge starts
WAIT_DELUGE=0
until [ ${WAIT_DELUGE} -gt 15 ]
do
	deluge-console -c ${DELUGE_CONFIG_DIR} config | grep -q "Failed to connect to"

	if [[ $? -eq 1 ]]; then
		break;
	fi

	echo "Waiting deluge..."
	sleep 1
done


deluge-console -c ${DELUGE_CONFIG_DIR} config --set $1 $2