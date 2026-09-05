#!/bin/bash
#SBATCH --job-name=bracken
#SBATCH --nodes=1
#SBATCH --cpus-per-task=15
#SBATCH --mem=100G
#SBATCH --output=gocheck.out


CAT_READS="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/GeCoCheck/cat_reads"

KREPORT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/GeCoCheck/kraken2_kreport"

K_OUTPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/GeCoCheck/kraken2_outraw"

R_OUTPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/GeCoCheck"

coverage_pipeline.py \
    --processors "${SLURM_CPUS_PER_TASK}" \
    --sample_metadata /mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/GeCoCheck/metadata.csv \
    --project_name MBRACE_NOV2025 \
    --fastq_dir "$CAT_READS" \
    --kraken_kreport_dir "$KREPORT" \
    --kraken_outraw_dir "$K_OUTPUT" \
    --output_dir "${R_OUTPUT}/GeCoCheck_out" \
    --coverage_program Both \
    --read_lim 100 \
    --skip_cleanup