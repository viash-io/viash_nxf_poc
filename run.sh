#!/bin/bash

export NXF_VER=21.10.6

nextflow run main.nf \
  -entry run_main \
  --publishDir output/ \
  # --publishDir output/auto/ \
  # --transcriptsDir output/transcripts/ \
  -resume  #-dump-hashes


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