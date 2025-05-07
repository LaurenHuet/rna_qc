#!/bin/bash

##BACKUP SCRIPTS

RUN=$1

rclone copy basespace/$RUN/ s3:oceanomics/OceanGenomes/illumina-rna/$RUN --checksum --progress

rclone copy pooled_raw/ s3:oceanomics/OceanGenomes/illumina-rna-sra --checksum --progress

rclone copy fastq/ pawsey0964:oceanomics-filtered-reads/ --checksum --progress