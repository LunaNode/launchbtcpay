#!/bin/bash

: "${BTCPAY_HOST:=[HOSTNAME]}"
: "${NBITCOIN_NETWORK:=[NETWORK]}"
: "${LETSENCRYPT_EMAIL:=[EMAIL]}"
: "${BTCPAY_DOCKER_REPO:=[REPOSITORY]}"
: "${BTCPAY_DOCKER_REPO_BRANCH:=[BRANCH]}"
: "${BTCPAYGEN_CRYPTO1:=[CRYPTO1]}"
: "${BTCPAYGEN_CRYPTO2:=[CRYPTO2]}"
: "${BTCPAYGEN_LIGHTNING:=[LIGHTNING]}"
: "${LIGHTNING_ALIAS:=[ALIAS]}"
: "${BTCPAYGEN_REVERSEPROXY:=nginx}"
: "${ACME_CA_URI:=https://acme-v01.api.letsencrypt.org/directory}"

BTCPAYGEN_ADDITIONAL_FRAGMENTS="opt-save-storage-s"

# Setup SSH access via private key
ssh-keygen -t rsa -f /root/.ssh/id_rsa_btcpay -q -P ""
echo "# Key used by BTCPay Server" >> /root/.ssh/authorized_keys
cat /root/.ssh/id_rsa_btcpay.pub >> /root/.ssh/authorized_keys

# Configure BTCPAY to have access to SSH
BTCPAY_HOST_SSHKEYFILE=/root/.ssh/id_rsa_btcpay

# Clone btcpayserver-docker
git clone $BTCPAY_DOCKER_REPO
cd btcpayserver-docker
git checkout $BTCPAY_DOCKER_REPO_BRANCH

. ./btcpay-setup.sh -i

[ -x "$(command -v /etc/init.d/sshd)" ] && nohup /etc/init.d/sshd restart &
[ -x "$(command -v /etc/init.d/ssh)" ] && nohup /etc/init.d/ssh restart &
