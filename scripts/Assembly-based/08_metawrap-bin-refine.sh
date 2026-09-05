#!/bin/bash
#SBATCH --nodes=1
#SBATCH --mem=300G
#SBATCH --cpus-per-task=100
#SBATCH --job-name=bin_refine
#SBATCH --output=bin_refine.out

META="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/BINNING/INITIAL_BINNING/metabat2_bins"
CONC="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/BINNING/INITIAL_BINNING/concoct_bins"

metawrap bin_refinement -o BIN_REFINEMENT -t 100 -A "$META" -B "$CONC" -c 50 -x 10