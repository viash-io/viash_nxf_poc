#!/bin/bash

export NXF_VER=21.10.6
export NXF_TEMP=tmp

nextflow run main.nf \
  -entry run_main \
  --publishDir output/ \
  -resume \
  -dump-hashes


# nextflow \
#   run https://github.com/viash-io/viash_nxf_poc.git \
#   -r main \
#   -main-script main.nf \
#   -entry run_main \
#   --publishDir output/ \
#   -resume

# nextflow run main.nf -entry run_main --publishDir output_stub/ -stub

# nextflow run target/nextflowpoc/poc/main.nf \
#   --input_one main.nf \
#   --input_multi '.nextflow.log.*' \
#   --publishDir output/