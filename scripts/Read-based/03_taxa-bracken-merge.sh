#!/bin/bash
#SBATCH --job-name=bracken_merge
#SBATCH --nodes=1
#SBATCH --cpus-per-task=30
#SBATCH --mem=100G
#SBATCH --output=bracken_merge.out
#SBATCH --error=bracken_merge.err

OUTPUT_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/KRAKEN/BRACKEN_OUTPUT"

MERGED_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/KRAKEN/BRACKEN_MERGED"

mkdir -p "${MERGED_DIR}"

combine_bracken_outputs.py \
  --files "${OUTPUT_DIR}"/PHYLUM/*.phylum.bracken \
  -o "${MERGED_DIR}/merged_output.phylum.bracken"

combine_bracken_outputs.py \
  --files "${OUTPUT_DIR}"/CLASS/*.class.bracken \
  -o "${MERGED_DIR}/merged_output.class.bracken"

combine_bracken_outputs.py \
  --files "${OUTPUT_DIR}"/ORDER/*.order.bracken \
  -o "${MERGED_DIR}/merged_output.order.bracken"

combine_bracken_outputs.py \
  --files "${OUTPUT_DIR}"/FAMILY/*.family.bracken \
  -o "${MERGED_DIR}/merged_output.family.bracken"

combine_bracken_outputs.py \
  --files "${OUTPUT_DIR}"/GENUS/*.genus.bracken \
  -o "${MERGED_DIR}/merged_output.genus.bracken"