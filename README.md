# rna_qc

## This pipline performs the QC of rna data from download to filtere and trimmed reads ready for downstream analysis. 

## The pipeline performs the following steps. 
1. Download from basespace
2. fastQC
3. pool lanes of data a repair if needed
4. fastp, trimming polyA tails
5. multiQC


## Running the pipeline 

## 1
Clone repo and supply the $RUN (from basespace), the date (of the sequening run) and the output directory in the 01_run_script.sh

## 2
Copy the 02_tidy_fastq_directory.sh script into the fastp output folder and run

## 3
Copy the 03_backup.sh script into the output directory and run. 
