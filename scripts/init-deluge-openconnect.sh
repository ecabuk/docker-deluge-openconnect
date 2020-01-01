#!/bin/bash

# Create config dir
if [[ ! -d "${DELUGE_CONFIG_DIR}" ]]; then
	mkdir -p "${DELUGE_CONFIG_DIR}"
fi

# Save pass to file
if [ ! -f "${OPENCONNECT_PASS_FILE}" ]; then
    echo ${OPENCONNECT_PASS} > "${OPENCONNECT_PASS_FILE}"
fi

# Create the configuration file
if [ ! -f "${OPENCONNECT_CONFIG_FILE}" ]; then
    cat > ${OPENCONNECT_CONFIG_FILE} <<EOF
user ${OPENCONNECT_USER}
no-dtls
EOF
fi

# Check config file for `servercert` entry
grep -q "^servercert" $OPENCONNECT_CONFIG_FILE

if [ $? -eq "1" ]; then
	# Get server cert if not defined by variable
	if [ -z "${OPENCONNECT_SERVER_CERT}" ]; then
		OPENCONNECT_SERVER_CERT=$(echo no | openconnect ${OPENCONNECT_SERVER} 2>&1 | grep servercert | awk '{print $2}')
		echo Server certificate obtained ${OPENCONNECT_SERVER_CERT}
	fi

	# Save server cert fingerprint to config file
	echo servercert ${OPENCONNECT_SERVER_CERT} >> ${OPENCONNECT_CONFIG_FILE}	
fi

# Get default dns server
DEFAULT_DNS=$(grep "nameserver" /etc/resolv.conf | head -n 1 | awk '{print $2}')

# Obtain the server's ip address
OPENCONNECT_SERVER_IP=$(host -4 -t A ${OPENCONNECT_SERVER} | head -n 1 | awk '{print $4}')

# Get default connection details
eval $(/sbin/ip route list match default | awk '{if($5!="tun0"){print "DEFAULT_GW="$3"\nDEFAULT_INT="$5; exit}}')
eval $(ip r l dev ${DEFAULT_INT} | awk '{if($5=="link"){print "GW_CIDR="$1; exit}}')

echo DEFAULT_GW=$DEFAULT_GW
echo DEFAULT_INT=$DEFAULT_INT
echo GW_CIDR=$GW_CIDR

# Disable IPv6 on Kernel
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1

# Disable IPv6 on Firewall
sed -i '/IPV6=yes/c\IPV6=no' /etc/default/ufw

# Forward dns requests to default route
if [[ $DEFAULT_DNS != 127.* ]]; then
	ip route add $DEFAULT_DNS via $DEFAULT_GW
fi

# Route local to default GW
ip route add $LOCAL_NETWORK via $DEFAULT_GW

# Route vpn server connection through default GW
ip route add $OPENCONNECT_SERVER_IP/32 via $DEFAULT_GW

# Firewall
yes | ufw reset
ufw enable
ufw default deny outgoing
ufw default deny incoming

# Allow outgoing connections through vpn
ufw allow out on tun0 from any to any

# Deny incoming connections to deluge through vpn
ufw deny in on tun0 to any port 8112,58846 proto tcp

# Allow incoming connections through vpn
ufw allow in on tun0 from any to any

# Allow DNS
ufw allow out from any to any port 53 proto udp

# Allow connection to vpn server (to be able to reconnect)
ufw allow out from any to ${OPENCONNECT_SERVER_IP}

# Allow access to deluge from local
ufw allow from ${LOCAL_NETWORK} to any port 8112,58846 proto tcp
ufw allow from ${GW_CIDR} to any port 8112,58846 proto tcp

# Start openconnect
supervisorctl start openconnect

# Configure Deluge
DELUGE_CONFIG_MODIFIED=0


# Set initial config
if [ ! -f "${DELUGE_CONFIG_DIR}/core.conf" ]; then
	# Directories
	mkdir -p ${DELUGE_DATA_DIR}/{autoadd,download,completed,torrentfiles}
	set-deluge-config.sh autoadd_location ${DELUGE_DATA_DIR}/autoadd
	set-deluge-config.sh download_location ${DELUGE_DATA_DIR}/download
	set-deluge-config.sh move_completed_path ${DELUGE_DATA_DIR}/completed
	set-deluge-config.sh torrentfiles_location ${DELUGE_DATA_DIR}/torrentfiles

	# Allow remote
	set-deluge-config.sh allow_remote true

	DELUGE_CONFIG_MODIFIED=1
fi

# Add default user
if [[ ! -z ${DELUGE_USER} && ! -z ${DELUGE_PASS} ]]; then
	add-deluge-user.sh "${DELUGE_USER}" "${DELUGE_PASS}"
fi

# Restart deluge on change
if [[ ${DELUGE_CONFIG_MODIFIED} -eq 1 ]]; then
	supervisorctl restart deluge
fi
