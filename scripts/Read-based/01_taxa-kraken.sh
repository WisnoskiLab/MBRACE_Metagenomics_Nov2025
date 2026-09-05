#!/bin/bash
#SBATCH --job-name=kraken_gtdb
#SBATCH --cpus-per-task=30
#SBATCH --mem=800G
#SBATCH --array=1-36
#SBATCH --output=kraken_%A_%a.out
#SBATCH --error=kraken_%A_%a.err

set -euo pipefail

INPUT_DIR="/mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/CLEAN_READS_CAT"
OUTPUT_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/KRAKEN/KRAKEN_OUTPUT"
DB="/mnt/scratch/wisnoskics/shared/databases/Kraken_GTDBv226"

REPORTS="$OUTPUT_DIR/KRAKEN_REPORTS"
RESULTS="$OUTPUT_DIR/KRAKEN_RESULTS"

mkdir -p "$REPORTS" "$RESULTS"

THREADS=${SLURM_CPUS_PER_TASK:-30}

FILES=("$INPUT_DIR"/*.fastq)

READS="${FILES[$SLURM_ARRAY_TASK_ID]}"
SAMPLE=$(basename "$READS" .fastq)

kraken2 \
  --db "$DB" \
  --threads "$THREADS" \
  --memory-mapping \
  --use-names \
  --report "$REPORTS/${SAMPLE}.kraken2.report" \
  --output "$RESULTS/${SAMPLE}.kraken2.output" \
  "$READS"