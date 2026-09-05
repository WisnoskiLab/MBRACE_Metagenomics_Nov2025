#!/bin/bash
#SBATCH --nodes=1
#SBATCH --mem=300G
#SBATCH --cpus-per-task=100
#SBATCH --job-name=bin_refine
#SBATCH --output=bin_refine.out

BIN="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/BINNING/BIN_REFINEMENT/metawrap_50_10_bins"
Assembly="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/ASSEMBLY-MEGAHIT/ASSEMBLY/megahit/final.contigs.fa"

metawrap blobology -a "$Assembly" \
 -t 100 \
 -o BLOBOLOGY \
 --bins "$BIN"\
 /mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/CLEAN_READS/W_*.fastq