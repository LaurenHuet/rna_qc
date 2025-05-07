#!/bin/bash
module load nextflow/24.04.3 

#add RUN DATE and OUTPUT directory here

bash 01_nextflow_run.sh "NOVA_250409_LA" "250409" "/scratch/pawsey0964/lhuet/rna-test" -resume