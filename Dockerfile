FROM ubuntu:bionic

# WEB UI
EXPOSE 8112

# GUI
EXPOSE 58846

RUN apt-get update && apt-get install -y \
    openconnect \
    deluged \
    deluge-web \
    deluge-console \
    supervisor \
    ufw \
    dnsutils \
 && rm -rf /var/lib/apt/lists/*	

# Supervisord config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Utils
COPY scripts/* /usr/local/bin/

# OpenConnect Hooks
COPY vpnc/post-connect.d/* /etc/vpnc/post-connect.d/
# Set deluge interface after connection
COPY scripts/set-deluge-listen-interface.sh /etc/vpnc/post-connect.d/
COPY scripts/set-deluge-listen-interface.sh /etc/vpnc/reconnect.d/

# Default Environment Variables
ENV OPENCONNECT_PASS_FILE=/run/openconnect.pass
ENV OPENCONNECT_CONFIG_FILE=/run/openconnect.conf
ENV DELUGE_CONFIG_DIR=/config
ENV DELUGE_DATA_DIR=/data
ENV LOCAL_NETWORK=192.168.1.0/24

CMD ["/usr/bin/supervisord"]
