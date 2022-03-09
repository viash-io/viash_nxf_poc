#!/bin/bash

# export NXF_VER=21.10.6
# nextflow run main.nf -entry run_main --publishDir output/ #-resume

unset NXF_VER
# use custom build of nextflow
bin/nextflow run main.nf -entry run_main --publishDir output/