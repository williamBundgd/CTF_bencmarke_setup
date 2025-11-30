#!/usr/bin/env bash
# NOTE: This file appends the /etc/hosts file with the DNS records of the endpoints.
#       It also adds the ca-certificate for the CTF to the host.
#       .
#       Please run this file using sudo.

DOMAIN_NAME="bench.test"
CA_FILE="/usr/local/share/ca-certificates/certCA.crt"    

GATEWAY=$(docker network inspect bridge | grep -oP '(?<=\"Gateway\":\s\").*(?=\")')

COUNT=$(cat /etc/hosts | grep -c $GATEWAY.*$DOMAIN_NAME)

if [ -z $GATEWAY ]; then
        echo "Gateway not found / network doesn't exists"
elif [ $COUNT == 0 ]; then
        echo "Insert hosts into /etc/hosts"
        sudo echo -e "$GATEWAY\tgit.$DOMAIN_NAME" >> /etc/hosts
        sudo echo -e "$GATEWAY\tdrone.$DOMAIN_NAME" >> /etc/hosts
        sudo echo -e "$GATEWAY\tregistry.$DOMAIN_NAME" >> /etc/hosts
        sudo echo -e "$GATEWAY\tinternalgit.$DOMAIN_NAME" >> /etc/hosts
        sudo echo -e "$GATEWAY\tinternaldrone.$DOMAIN_NAME" >> /etc/hosts
        sudo echo -e "$GATEWAY\tinternalregistry.$DOMAIN_NAME" >> /etc/hosts
        sudo echo -e "$GATEWAY\tinternalrunnervm.$DOMAIN_NAME" >> /etc/hosts
        sudo echo -e "$GATEWAY\tinternalrunnerlocal.$DOMAIN_NAME" >> /etc/hosts
else
        echo "Hosts not added to /etc/hosts"
fi

if [ -f $CA_FILE ]; then
   echo "File $CA_FILE exists."
else
   echo "File $CA_FILE does not exist."
   echo "Adding $CA_FILE and updating ca-certificates."
   sudo cp proxy/ssl/certCA.crt $CA_FILE
   sudo update-ca-certificates --fresh
   echo "You might restart your PC to ensure ca-certificate is in use"
fi
