#!/bin/bash
#SBATCH --nodes=1
#SBATCH --mem=300G
#SBATCH --cpus-per-task=100
#SBATCH --job-name=bin
#SBATCH --output=bin.out
#SBATCH --error=bin.err 
  
metawrap binning -o /mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/BINNING/INITIAL_BINNING \
 -t 100 \
 -a /mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/ASSEMBLY-MEGAHIT/ASSEMBLY/megahit/final.contigs.fa \
 --metabat2 \
 --maxbin2 \
 --concoct \
 /mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/CLEAN_READS/W_*fastq