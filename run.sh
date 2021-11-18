#!/bin/bash

export NXF_VER=21.10.0 

nextflow run main.nf -entry run_main --publishDir output/ 
