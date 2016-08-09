# Setup a Strongswan IPSec (& L2TP) Server

> NOTE: This is probably securer than using https://github.com/philplckthun/setup-simple-ipsec-l2tp-vpn
> Furthermore it supports both L2TP and regular IPSec connections

## Installation

This script doesn't need a domain or specific public IP to work.

```
curl -L -O https://raw.github.com/philplckthun/setup-strong-strongswan/master/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

The script will lead you through the installation process. If you haven't run
this script before it will ask you to enter credentials for the VPN, namely:

- a username
- a password
- a PSK (pre-shared key)

For upgrading Strongswan you can just run the script again. Remember to back up
your custom IPSec configuration files beforehand.

## Usage

This installs the `vpn-assist` init.d script. Systemd is backwards compatible to these
scripts and thus you can use it to `start|stop|restart` the VPN server, which
should also start itself automatically on startup.

You can manage accounts for your VPN via `/etc/ipsec.secrets` and `etc/ppp/chap-secrets`.
[@zackdevine's account managing script automates this process](https://github.com/zackdevine/setup-strongswan-vpn-account)

## Uninstallation

Download the Strongswan source and run:

```
make uninstall
```

Then uninstall `xl2tpd` and remove `/etc/init.d/vpn-assist`. That should
suffice for a rather clean uninstallation.
