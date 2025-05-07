#!/bin/bash

module load nextflow/24.04.3

runid=$1
date=$2
outdir=$3

nextflow run main.nf \
    --run $runid \
    -profile setonix \
    --outdir $outdir/$runid \
    --date $date \
    --bs_config ~/.basespace/default.cfg