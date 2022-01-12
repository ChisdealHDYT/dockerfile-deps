#!/bin/bash
set -e

if [[ "$1" == "zenzo-cli" || "$1" == "zenzo-tx" || "$1" == "zenzod" || "$1" == "test_zenzo" ]]; then
	mkdir -p "$BITCOIN_DATA"

	CONFIG_PREFIX=""
    if [[ "${BITCOIN_NETWORK}" == "testnet" ]]; then
        CONFIG_PREFIX=$'testnet=1\n[test]'
    fi
    if [[ "${BITCOIN_NETWORK}" == "mainnet" ]]; then
        CONFIG_PREFIX=$'mainnet=1\n[main]'
    fi

	cat <<-EOF > "$BITCOIN_DATA/zenzo.conf"
	${CONFIG_PREFIX}
	printtoconsole=1
	rpcallowip=::/0
	${BITCOIN_EXTRA_ARGS}
	EOF
	chown zenzo:zenzo "$BITCOIN_DATA/zenzo.conf"

	# ensure correct ownership and linking of data directory
	# we do not update group ownership here, in case users want to mount
	# a host directory and still retain access to it
	chown -R zenzo "$BITCOIN_DATA"
	ln -sfn "$BITCOIN_DATA" /home/zenzo/.zenzo
	chown -h bzenzo:zenzo /home/zenzo/.zenzo

	exec gosu zenzo "$@"
else
	exec "$@"
fi
