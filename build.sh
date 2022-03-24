#!/bin/bash

rm -r target/nextflowpoc
viash build src/poc/config.vsh.yaml -p nextflowpoc -o target/nextflowpoc/poc