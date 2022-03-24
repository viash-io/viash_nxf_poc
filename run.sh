#!/bin/bash

# export NXF_VER=21.10.6
# nextflow run main.nf -entry run_main --publishDir output/ #-resume

export NXF_TEMP=tmp 

unset NXF_VER
# use custom build of nextflow
bin/nextflow run main.nf -entry run_main --publishDir output/

# bin/nextflow run main.nf -entry run_main --publishDir output_stub/ -stub

# bin/nextflow run target/nextflow/poc_new/main.nf \
#   --input_one main.nf \
#   --input_multi '.nextflow.log.*' \
#   --publishDir output/