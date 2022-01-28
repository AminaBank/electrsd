#!/bin/bash
set -euo pipefail

# run the test eventhough it wil fail, but it will download the binaries
cargo test --features trigger,bitcoind_22_0,electrs_0_8_10 -- --nocapture || true

rm -rf data/
mkdir -p data/{bitcoin,electrum,electrs}
mkdir -p /tmp/.tmpLRUr2F
mkdir -p /tmp/.tmpJP3kJL

cleanup() {
  trap - SIGTERM SIGINT
  set +eo pipefail
  jobs
  for j in `jobs -rp`
  do
  	kill $j
  	wait $j
  done
}
trap cleanup SIGINT SIGTERM EXIT

BTCD=$(find / -name bitcoind -type f)
ELECTRS=$(find / -name electrs -type f)

tail_log() {
	tail -n +0 -F $1 || true
}

echo "Starting $($BTCD -version | head -n1)..."
$BTCD -regtest -datadir=/tmp/.tmpLRUr2F -rpcport=34397 -port=33487 &
BITCOIND_PID=$!

export RUST_LOG=electrs=debug
$ELECTRS \
  --db-dir=/tmp/.tmpJP3kJL \
  --cookie-file=/tmp/.tmpDR25TB/regtest/.cookie \
  --daemon-rpc-addr=127.0.0.1:33931 \
  --jsonrpc-import
  --electrum-rpc-addr=0.0.0.0:33461 \
  --monitoring-addr=0.0.0.0:37949 \
  --vvv \
  2> data/electrs/regtest-debug.log &
ELECTRS_PID=$!
tail_log data/electrs/regtest-debug.log | grep -m1 "serving Electrum RPC"
curl localhost:33461 -o metrics.txt

