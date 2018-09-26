#!/bin/bash

cat <<EOM >/root/run.py
import os
import subprocess
import sys

hostname = sys.argv[1]
network = sys.argv[2]
email = sys.argv[3]
repository = sys.argv[4]
branch = sys.argv[5]
coinstr = sys.argv[6]
lightning = sys.argv[7]
alias = sys.argv[8]

reverseproxy = 'nginx'
acme_uri = 'https://acme-v01.api.letsencrypt.org/directory'
coinmap = {
	'btc': '/var/lib/docker/volumes/generated_bitcoin_datadir/_data/blocks',
	'ltc': '/var/lib/docker/volumes/generated_litecoin_datadir/_data/blocks',
}

# setup SSH access via private key
subprocess.call(['ssh-keygen', '-t', 'rsa', '-f', '/root/.ssh/id_rsa_btcpay', '-q', '-P', ''])
with open('/root/.ssh/id_rsa_btcpay.pub', 'r') as f:
	pubkey = f.read()
with open('/root/.ssh/authorized_keys', 'w') as f:
	f.write("# Key used by BTCPay Server\n")
	f.write(pubkey)

# clone btcpayserver-docker
subprocess.call(['git', 'clone', repository, 'btcpayserver-docker'], cwd='/root/')
subprocess.call(['git', 'checkout', branch], cwd='/root/btcpayserver-docker')

env = os.environ.copy()
crypto_counter = 1

# setup volumes for coins
volumes = []
for fname in os.listdir('/dev'):
	if len(fname) == 3 and fname.startswith('vd') and fname not in ['vda', 'vdb']:
		volumes.append(fname)
coins = coinstr.split(',')
for coin in coins:
	if coin not in coinmap or len(volumes) == 0:
		continue
	volume = '/dev/' + volumes[0]
	volumes = volumes[1:]
	path = coinmap[coin]
	try:
		os.makedirs(path, 0o755)
	except FileExistsError:
		pass
	subprocess.call(['mkfs.ext4', volume])
	subprocess.call(['mount', volume, path])
	uuid = subprocess.check_output(['blkid', volume]).decode('utf-8').split('UUID="')[1].split('"')[0]
	with open('/etc/fstab', 'a') as f:
		f.write("UUID={} {} ext4 defaults 0 2\n".format(uuid, path))

	env['BTCPAYGEN_CRYPTO{}'.format(crypto_counter)] = coin
	crypto_counter += 1

env['BTCPAY_HOST'] = hostname
env['NBITCOIN_NETWORK'] = network
env['LETSENCRYPT_EMAIL'] = email
env['BTCPAY_DOCKER_REPO'] = repository
env['BTCPAY_DOCKER_REPO_BRANCH'] = branch
env['BTCPAYGEN_LIGHTNING'] = lightning
env['LIGHTNING_ALIAS'] = alias
env['BTCPAYGEN_ADDITIONAL_FRAGMENTS'] = 'opt-save-storage-s'
subprocess.call(['bash', '-c', '. ./btcpay-setup.sh -i'], env=env, cwd='/root/btcpayserver-docker')
EOM

# for now this should be enough time to attach volumes
# later on we may need to do something more robust
sleep 20
/usr/bin/python3 /root/run.py "[HOSTNAME]" "[NETWORK]" "[EMAIL]" "[REPOSITORY]" "[BRANCH]" "[COINS]" "[LIGHTNING]" "[ALIAS]"

[ -x "$(command -v /etc/init.d/sshd)" ] && nohup /etc/init.d/sshd restart &
[ -x "$(command -v /etc/init.d/ssh)" ] && nohup /etc/init.d/ssh restart &
