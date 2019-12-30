# Deluge - OpenConnect

Deluge is a full-featured BitTorrent client for Linux, OS X, Unix and Windows.
It uses libtorrent in its backend and features multiple user-interfaces including: GTK+, web and console.
It has been designed using the client server model with a daemon process that handles all the bittorrent activity.
The Deluge daemon is able to run on headless machines with the user-interfaces being able to connect remotely from any platform.
This Docker includes OpenConnect client to ensure a secure and private connection to the Internet, including use of UFW to prevent IP leakage when the tunnel is down.

## Application

- [Deluge](https://deluge-torrent.org/)
- [OpenConnect](https://www.infradead.org/openconnect/)

## Usage

```sh
docker run -d \
	--cap-add=NET_ADMIN \
	-p 8112:8112 \
	-p 58846:58846 \
	--name=<container name> \
	-v <path for data files>:/data \
	-v <path for config files>:/config \
	-e LOCAL_NETWORK=<(required) Your local network. Default: 192.168.1.0/24> \
	-e OPENCONNECT_SERVER=<(required) vpn host> \
	-e OPENCONNECT_USER=<(required) vpn username> \
	-e OPENCONNECT_PASS=<(required) vpn password> \
	-e DELUGE_USER=<(optional)remote deluge user name> \
	-e DELUGE_PASS=<(optional)remote deluge user password> \
	ecabuk/deluge-openconnect
```

### Environment Variables

| Variable                	| Default               	| Description                                                                           |
|-------------------------	|-----------------------	|--------------------------------------------------------------------------------------	|
| OPENCONNECT_SERVER      	| -                     	| (Required) VPN server host.                                                          	|
| OPENCONNECT_USER        	| -                     	| (Required) VPN username.                                                              |
| OPENCONNECT_PASS        	| -                     	| (Required, if password file is not used) VPN password.                                |
| OPENCONNECT_PASS_FILE   	| /run/openconnect.pass 	| OpenConnect password file path.                           							|
| OPENCONNECT_CONFIG_FILE 	| /run/openconnect.conf 	| OpenConnect config file path.															|
| OPENCONNECT_SERVER_CERT   | -                         | Server certificate signature.                                                         |
| LOCAL_NETWORK           	| 192.168.1.0/24        	| Your local network. It is required for the firewall settings.                         |
| DELUGE_USER             	| -                     	| Deluge remote-user name.                                                              |
| DELUGE_PASS             	| -                     	| Deluge remote-user password.                                                          |

### Password File

You can supply the password as a file. Put your password in a file and mount that file to `/run/openconnect.pass`.

### Custom OpenConnect Config File

To use your custom config file, mount it to `/run/openconnect.conf`.

### Managing Users

Once you started container you can add/remove deluge users.

You can use `DELUGE_USER`, `DELUGE_PASS` environment variables to add first user.

**To add an another users:**

```sh
docker exec <container name> add-deluge-user.sh <username> <password>
```


### WebUI

Web user interface uses port `8112` by default.
Depending on your configuration, you can reach to web ui:

[http://127.0.0.1:8112](http://127.0.0.1:8112)

Default password: `deluge`

**Don't forget to change default password!**

### GUI

First, you need to install Deluge client to your computer.

 - **Debian:** `apt-get install deluge-gtk`
 - **MacOSX:** `brew cask install deluge`

If you can't see `Connection Manager` when you started the application,
you should disable the `Classic Mode` from the `Preferences` > `Interface` > `Classic Mode` *(and restart)*.


## Todo

- [ ] Add support for port forwarding.
- [ ] Add secondary local network option.

## Inspired by
- [binhex/arch-delugevpn](https://hub.docker.com/r/binhex/arch-delugevpn)
- [haugene/transmission-openvpn](https://hub.docker.com/r/haugene/transmission-openvpn)