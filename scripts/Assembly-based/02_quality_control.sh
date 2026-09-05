#!/bin/bash
#SBATCH --mem=200G
#SBATCH --cpus-per-task=35
#SBATCH --job-name=merge

# Change these two folders only
INPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/w_merged_fastq_files"
OUTPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/s_qc-files"

# Existing QC output folder
OUTPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/s_qc-files"

# FastQC reports are already here
FASTQC_DIR="$OUTPUT/fastqc_reports"

# MultiQC output will be saved here
MULTIQC_DIR="$OUTPUT/multiqc_report"

mkdir -p "$MULTIQC_DIR"

echo "FastQC reports folder: $FASTQC_DIR"
echo "MultiQC output folder: $MULTIQC_DIR"
echo "Running MultiQC..."

multiqc "$FASTQC_DIR" \
  --outdir "$MULTIQC_DIR" \
  --force

echo "MultiQC completed."
echo "Open this report:"
echo "$MULTIQC_DIR/multiqc_report.html"