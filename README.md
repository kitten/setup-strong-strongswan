# Setup a (really) strong StrongSwan VPN server for Ubuntu and Debian

> NOTE: As far as I know, this is the highest security you can get with a VPN!
> It is faster than using L2TP, stronger than PPTP, as strong as OpenVPN, secured using certificates and passwords, and "Great Firewall of China"-proof

**THE SCRIPT ITSELF IS CURRENTLY UNTESTED!!!**

This has been tested on:

- Digital Ocean: Ubuntu 14.04 x64 (Trusty)

This has been tested with:

- Mac OSX 10.10 (Yosemity) [Cisco IPSec]
- Android 4.4.4 CM11S (StrongSwan App 1.4.0)

**Feel free to test it on more distributions with more clients and please report back to me!**

Copyright (C) 2014 Phil Plückthun <phil@plckthn.me><br>
[Based on the work of Viljo Viitanen](https://github.com/viljoviitanen/setup-simple-pptp-vpn) (Setup Simple PPTP VPN server for Ubuntu and Debian)
Based on the work of Thomas Sarlandie (Copyright 2012)

# Installation

The server will need a domain to connect! (e.g. *vpn.example.com*)

Please set the hostname of your machine to a domain name under which the server will be reachable. Otherwise you can enter it during the setup.

```
wget https://raw.github.com/philplckthun/setup-strong-strongswan/master/setup.sh
sudo sh setup.sh
```

The script will lead you through the installation process.

During installation you have to enter a password, which will be universally used.

# Getting Started

* On Mac OSX you should use XAuth (Cisco IPSec)
* On iOS you should try the Cisco IPSec method too
* On Android you should use the StrongSwan App

## Cisco IPSec

Download the certificate at */var/xauth.p12* and install it.

Use the following data to connect:

```
Host / Gateway: [Your chosen hostname / domain]
Accountname: "xauth"
Password: [The random password / your chosen password, created during setup]
Certificate: "xauth (strongSwan Root CA)"
```

## Android StrongSwan

Download the certificate at */var/eap.p12* and install it.

Use the following data to connect:

```
Gateway: [Your chosen hostname / domain]
Type: "IKEv2 Certificate + EAP (Username/Password)"
Username: "eap"
Password: [The random password / your chosen password, created during setup]
Certificate: "EAP Certificate"
CA Certificate: "strongSwan Root CA"
```

**Enjoy your very own (really strong) VPN!**

Some Notes
==========

Clients are configured to use Comodo's Public DNS servers, when
the VPN connection is active:
http://www.comodo.com/secure-dns/

Only two accounts are generated. Each having one certificate! The accounts can be used in the following way:

* Cisco IPSec with XAuth Hybrid and Certificate Authentication (IKEv1)
* StrongSwan IPSec EAP MSChapv2 (IKEv2)

*In the future I might add the ability to generate more accounts with more compatibilitys.*

If you keep the VPN server generated with this script on the internet for a
long time (days or more), consider securing it to possible attacks!
