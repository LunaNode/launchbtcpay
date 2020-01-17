#!/bin/bash

cat <<EOM >/root/run.py
import os
import subprocess
import sys
import time

hostname = '[HOSTNAME]'
network = '[NETWORK]'
email = '[EMAIL]'
repository = '[REPOSITORY]'
branch = '[BRANCH]'
coinstr = '[COINS]'
lightning = '[LIGHTNING]'
alias = '[ALIAS]'

reverseproxy = 'nginx'
acme_uri = 'https://acme-v01.api.letsencrypt.org/directory'
coinmap = {
	'btc': '/var/lib/docker/volumes/generated_bitcoin_datadir/_data/blocks',
	'lbtc': '/var/lib/docker/volumes/generated_elements_datadir/_data/liquidv1/blocks',
	'ltc': '/var/lib/docker/volumes/generated_litecoin_datadir/_data/blocks',
	'grs': '/var/lib/docker/volumes/generated_groestlcoin_datadir/_data/blocks/',
	'btg': '/var/lib/docker/volumes/generated_bgold_datadir/_data/blocks',
	'ftc': '/var/lib/docker/volumes/generated_feathercoin_datadir/_data/blocks',
	'via': '/var/lib/docker/volumes/generated_viacoin_datadir/_data/blocks',
	'doge': '/var/lib/docker/volumes/generated_dogecoin_datadir/_data/blocks',
	'mona': '/var/lib/docker/volumes/generated_monacoin_datadir/_data/blocks',
}
coinmapTestnet = {
	'btc': '/var/lib/docker/volumes/generated_bitcoin_datadir/_data/testnet3/blocks',
	'lbtc': '/var/lib/docker/volumes/generated_elements_datadir/_data/testnet3/blocks',
	'ltc': '/var/lib/docker/volumes/generated_litecoin_datadir/_data/testnet4/blocks',
	'grs': '/var/lib/docker/volumes/generated_groestlcoin_datadir/_data/testnet3/blocks/',
	'btg': '/var/lib/docker/volumes/generated_bgold_datadir/_data/testnet3/blocks',
	'ftc': '/var/lib/docker/volumes/generated_feathercoin_datadir/_data/testnet4/blocks',
	'via': '/var/lib/docker/volumes/generated_viacoin_datadir/_data/testnet3/blocks',
	'doge': '/var/lib/docker/volumes/generated_dogecoin_datadir/_data/testnet3/blocks',
	'mona': '/var/lib/docker/volumes/generated_monacoin_datadir/_data/testnet3/blocks',
}

# clone btcpayserver-docker
if not os.path.exists('/root/btcpayserver-docker'):
	subprocess.call(['git', 'clone', repository, 'btcpayserver-docker'], cwd='/root/')
	subprocess.call(['git', 'checkout', branch], cwd='/root/btcpayserver-docker')

env = os.environ.copy()
coins = coinstr.split(',')

# setup volumes for coins (if not already setup)
mount_output = subprocess.check_output(['mount']).decode('utf-8')
if 'vdc' not in mount_output:
	volumes = []
	for fname in os.listdir('/dev'):
		if len(fname) == 3 and fname.startswith('vd') and fname not in ['vda', 'vdb']:
			volumes.append(fname)
	for coin in coins:
		if coin not in coinmap or len(volumes) == 0:
			continue
		volume = '/dev/' + volumes[0]
		volumes = volumes[1:]
		if network == 'testnet':
			path = coinmapTestnet[coin]
		else:
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

crypto_counter = 1
for coin in coins:
	if coin in coinmap:
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
env['BTCPAY_ENABLE_SSH'] = 'true'

for i in range(5):
	popen = subprocess.Popen(
		['bash', '-c', '. ./btcpay-setup.sh -i'],
		stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
		env=env, cwd='/root/btcpayserver-docker'
	)
	had_error = False
	for line in popen.stdout:
		sys.stdout.buffer.write(b'[btcpay-setup] ')
		sys.stdout.buffer.write(line)
		if b'Could not resolve host:' in line or b'docker-compose: command not found' in line:
			had_error = True
	popen.stdout.close()
	return_code = popen.wait()
	if return_code == 0 and not had_error:
		break
	else:
		print('launcher: btcpay-setup script had error, retrying in 10 seconds')
		time.sleep(10)
		continue
EOM

# for now this should be enough time to attach volumes
# later on we may need to do something more robust
sleep 20
/usr/bin/python3 /root/run.py

[ -x "$(command -v /etc/init.d/sshd)" ] && nohup /etc/init.d/sshd restart &
[ -x "$(command -v /etc/init.d/ssh)" ] && nohup /etc/init.d/ssh restart &
