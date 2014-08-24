#!/bin/sh
#    Setup Strong StrongSwan server for Ubuntu and Debian
#
#    Copyright (C) 2014 Phil Plückthun <phil@plckthn.me>
#    Based on the work of Viljo Viitanen (Setup Simple PPTP VPN server for Ubuntu and Debian)
#    Based on the work of Thomas Sarlandie (Copyright 2012)
#
#    This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
#    Unported License: http://creativecommons.org/licenses/by-sa/3.0/

if [ `id -u` -ne 0 ]
then
  echo "Please start this script with root privileges!"
  echo "Try again with sudo."
  exit 0
fi

lsb_release -c | grep trusty > /dev/null
if [ "$?" = "1" ]
then
  echo "This script was designed to run on Ubuntu 14.04 Trusty!"
  echo "Do you wish to continue anyway?"
  while true; do
    read -p "" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit 0;;
        * ) echo "Please answer with Yes or No [y|n].";;
    esac
  done
  echo ""
fi

echo "This script will install a StrongSwan VPN Server"
echo "Do you wish to continue?"

while true; do
  read -p "" yn
  case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit 0;;
      * ) echo "Please answer with Yes or No [y|n].";;
  esac
done

echo ""

# Generate a random key
generateKey () {
  P1=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  P2=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  P3=`cat /dev/urandom | tr -cd abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789 | head -c 3`
  SECUREKEY="$P1$P2$P3"
}

echo "The VPN needs a password, which will be used for both, authentication and certificate encryption."
echo "Do you wish to set it yourself?"
echo "(Otherwise a random key is generated)"
while true; do
  read -p "" yn
  case $yn in
      [Yy]* ) echo ""; echo "Enter your preferred key:"; read -p "" SECUREKEY; break;;
      [Nn]* ) generateKey; break;;
      * ) echo "Please answer with Yes or No [y|n].";;
  esac
done

echo ""
echo "The key you chose is: '$SECUREKEY'."
echo "Please save it, because you'll need it to connect and set up the certificates!"
echo ""

echo "The VPN needs a domain. Do you wish to set it yourself?"
echo "(Otherwise the hostname is used)"
while true; do
  read -p "" yn
  case $yn in
      [Yy]* ) echo ""; echo "Enter your preferred hostname:"; read -p "" HOSTNAME; break;;
      [Nn]* ) HOSTNAME=`hostname`; break;;
      * ) echo "Please answer with Yes or No [y|n].";;
  esac
done

echo ""
echo "============================================================"
echo ""

echo "Installing necessary dependencies..."

apt-get update > /dev/null
apt-get upgrade > /dev/null
apt-get install build-essential openssl wget -y  > /dev/null

if [ "$?" = "1" ]
then
  echo "An unexpected error occured!"
  exit 0
fi

echo "Installing StrongSwan..."
apt-get install libstrongswan strongswan strongswan-ike strongswan-plugin-af-alg strongswan-plugin-agent strongswan-plugin-dnscert strongswan-plugin-dnskey strongswan-plugin-eap-gtc strongswan-plugin-eap-md5 strongswan-plugin-eap-mschapv2 strongswan-plugin-fips-prf strongswan-plugin-openssl strongswan-plugin-pubkey strongswan-plugin-unbound strongswan-plugin-xauth-eap strongswan-plugin-xauth-generic strongswan-plugin-xauth-noauth strongswan-plugin-xauth-pam strongswan-starter -y > /dev/null

if [ "$?" = "1" ]
then
  echo "An unexpected error occured!"
  exit 0
fi

# Compile and install StrongSwan
# mkdir -p /opt/src
# cd /opt/src
# echo "Downloading StrongSwan's source..."
# wget -qO- http://download.strongswan.org/strongswan-5.2.0.tar.gz | tar xvz > /dev/null
# cd strongswan-5.2.0
# echo "Configuring StrongSwan..."
# ./configure > /dev/null
# echo "Installing StrongSwan..."
# make install > /dev/null

if [ "$?" = "1" ]
then
  echo "An unexpected error occured!"
  exit 0
fi

echo "Generating /var folder"
mkdir /var > /dev/null
chmod -R 755 /var

echo "Creating all necessary certificates..."

ipsec pki --gen --type rsa --size 4096 --outform pem > /etc/ipsec.d/private/strongswanKey.pem
chmod 600 /etc/ipsec.d/private/strongswanKey.pem
ipsec pki --self --ca --lifetime 3650 --in /etc/ipsec.d/private/strongswanKey.pem --type rsa --dn "C=CH, O=strongSwan, CN=strongSwan Root CA" --outform pem > /etc/ipsec.d/cacerts/strongswanCert.pem
ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/vpnHostKey.pem
chmod 600 /etc/ipsec.d/private/vpnHostKey.pem
ipsec pki --pub --in /etc/ipsec.d/private/vpnHostKey.pem --type rsa | ipsec pki --issue --lifetime 730 --cacert /etc/ipsec.d/cacerts/strongswanCert.pem --cakey /etc/ipsec.d/private/strongswanKey.pem --dn "C=CH, O=strongSwan, CN=$HOSTNAME" --san $HOSTNAME --flag serverAuth --flag ikeIntermediate --outform pem > /etc/ipsec.d/certs/vpnHostCert.pem

ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/xauthKey.pem
chmod 600 /etc/ipsec.d/private/xauthKey.pem
ipsec pki --pub --in /etc/ipsec.d/private/xauthKey.pem --type rsa | ipsec pki --issue --lifetime 730 --cacert /etc/ipsec.d/cacerts/strongswanCert.pem --cakey /etc/ipsec.d/private/strongswanKey.pem --dn "C=CH, O=strongSwan, CN=xauth" --san $HOSTNAME --outform pem > /etc/ipsec.d/certs/xauthCert.pem
openssl pkcs12 -export -inkey /etc/ipsec.d/private/xauthKey.pem -in /etc/ipsec.d/certs/xauthCert.pem -name "XAuth VPN Certificate" -certfile /etc/ipsec.d/cacerts/strongswanCert.pem -caname "strongSwan Root CA" -out /var/xauth.p12

ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/eapKey.pem
chmod 600 /etc/ipsec.d/private/eapKey.pem
ipsec pki --pub --in /etc/ipsec.d/private/eapKey.pem --type rsa | ipsec pki --issue --lifetime 730 --cacert /etc/ipsec.d/cacerts/strongswanCert.pem --cakey /etc/ipsec.d/private/strongswanKey.pem --dn "C=CH, O=strongSwan, CN=eap" --san $HOSTNAME --outform pem > /etc/ipsec.d/certs/eapCert.pem
openssl pkcs12 -export -inkey /etc/ipsec.d/private/eapKey.pem -in /etc/ipsec.d/certs/eapCert.pem -name "EAP VPN Certificate" -certfile /etc/ipsec.d/cacerts/strongswanCert.pem -caname "strongSwan Root CA" -out /var/eap.p12

openssl x509 -in /etc/ipsec.d/cacerts/strongswanCert.pem -outform DER -out /etc/ipsec.d/cacerts/strongswanCert.der
cp /etc/ipsec.d/cacerts/strongswanCert.der /var/strongswanCert.der

echo "Preparing various configuration files..."

cat > /etc/ipsec.conf <<EOF
# ipsec.conf - strongSwan IPsec configuration file

config setup
        uniqueids=never
        charondebug="cfg 2, dmn 2, ike 2, net 2"

conn %default
        keyexchange=ikev2
        ike=aes128-sha256-ecp256,aes256-sha384-ecp384,aes128-sha256-modp2048,aes256-sha384-modp4096,aes256-sha256-modp4096,aes128-sha256-modp1536,aes256-sha3$
        esp=aes128gcm16-ecp256,aes256gcm16-ecp384,aes128-sha256-ecp256,aes256-sha384-ecp384,aes128-sha256-modp2048,aes256-sha384-modp4096,aes256-sha256-modp4$
        dpdaction=clear
        dpddelay=300s
        rekey=no
        left=%any
        leftsubnet=0.0.0.0/0
        leftcert=vpnHostCert.pem
        right=%any
        rightdns=8.26.56.26,8.20.247.20
        rightsourceip=172.16.16.0/24

conn IPSec-IKEv2
        keyexchange=ikev2
        auto=add

conn IPSec-IKEv2-EAP
        also="IPSec-IKEv2"
        rightauth=pubkey
        rightauth2=eap-mschapv2
        rightsendcert=never
        eap_identity=%any

conn CiscoIPSec
        esp=aes256-sha256-modp2048,aes256-sha1!
        ike=aes256-sha1-modp1536,aes256-sha512-modp1024,aes256-sha1-modp1024!
        keyexchange=ikev1
        leftauth=pubkey
        rightauth=pubkey
        rightauth2=xauth
        auto=add
        leftid=@$HOSTNAME

EOF

cat > /etc/ipsec.secrets <<EOF
# This file holds shared secrets or RSA private keys for authentication.

# RSA private key for this host, authenticating it to any other host
# which knows the public part.  Suitable public keys, for ipsec.conf, DNS,
# or configuration of other implementations, can be extracted conveniently
# with "ipsec showhostkey".

: RSA vpnHostKey.pem
eap : EAP "$SECUREKEY"
xauth : XAUTH "$SECUREKEY"
EOF

cat > /etc/ipsec.secrets <<EOF
# strongswan.conf - strongSwan configuration file
#
# Refer to the strongswan.conf(5) manpage for details
#
# Configuration changes should be made in the included files

charon {
        load_modular = yes
        plugins {
                include strongswan.d/charon/*.conf
        }
}

include strongswan.d/*.conf
EOF

/bin/cp -f /etc/rc.local /etc/rc.local.old
cat > /etc/rc.local <<EOF
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

iptables --table nat --append POSTROUTING --jump MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
for each in /proc/sys/net/ipv4/conf/*
do
  echo 0 > $each/accept_redirects
  echo 0 > $each/send_redirects
done

/usr/sbin/service ipsec restart
/usr/sbin/service strongswan restart

exit 0
EOF

echo "Applying changes..."

iptables --table nat --append POSTROUTING --jump MASQUERADE
echo 1 > /proc/sys/net/ipv4/ip_forward
for each in /proc/sys/net/ipv4/conf/*
do
  echo 0 > $each/accept_redirects
  echo 0 > $each/send_redirects
done

ipsec rereadsecrets > /dev/null

echo "Starting StrongSwan services..."

/usr/sbin/service strongswan restart > /dev/null
/usr/sbin/service ipsec restart > /dev/null

echo "Success!"
echo ""

echo "============================================================"
echo "Host: $HOSTNAME"
echo "Password: $SECUREKEY"
echo "Download the certificates: /var/xauth.p12; /var/eap.p12"
echo "(Please reboot to ensure, that all changes are applied)"
echo "============================================================"

sleep 2
exit 0
