#!/bin/bash

VPN_INTERFACE=$(ip addr show tun0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)
echo "${VPN_INTERFACE}" | grep -q "does not exist"

if [ "$?" = '0' ] ; then
	>&2 echo "Interface 'tun0' does not exist."
	exit 1;
fi

/usr/local/bin/set-deluge-config.sh listen_interface ${VPN_INTERFACE}