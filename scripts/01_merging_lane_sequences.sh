#!/bin/bash
#SBATCH --nodes=1
#SBATCH --mem=200G
#SBATCH --cpus-per-task=20
#SBATCH --job-name=merge

# Change these two folders only
INPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/w_shotgun_sequences"
OUTPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/w_merged_fastq_files"

mkdir -p "$OUTPUT"

for sample in $(ls "$INPUT"/*_L001_R1_001.fastq.gz | sed 's/_L001_R1_001.fastq.gz//' | xargs -n1 basename)
do
    echo "Merging $sample"

    cat "$INPUT/${sample}_L001_R1_001.fastq.gz" \
        "$INPUT/${sample}_L002_R1_001.fastq.gz" \
        > "$OUTPUT/${sample}_R1.fastq.gz"

    cat "$INPUT/${sample}_L001_R2_001.fastq.gz" \
        "$INPUT/${sample}_L002_R2_001.fastq.gz" \
        > "$OUTPUT/${sample}_R2.fastq.gz"
done

echo "Done merging lanes."