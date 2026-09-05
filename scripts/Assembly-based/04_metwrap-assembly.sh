#!/bin/bash
#SBATCH --job-name=megahit
#SBATCH --mem=1000G
#SBATCH --cpus-per-task=96
#SBATCH --output=all-megahit_%j.out  
#SBATCH --error=all-megahit_%j.err 

metawrap assembly -1 MERGED_CLEAN_READS/ALL_READS_R1.fastq \
-2 MERGED_CLEAN_READS/ALL_READS_R2.fastq \
-m 200 \
-t 96 \
--megahit \
-o ASSEMBLY