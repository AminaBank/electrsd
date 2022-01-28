#!/bin/sh 

docker build -t rust-electrsd .
docker run -it rust-electrsd cargo test --features trigger,bitcoind_22_0,electrs_0_8_10 -- --nocapture
