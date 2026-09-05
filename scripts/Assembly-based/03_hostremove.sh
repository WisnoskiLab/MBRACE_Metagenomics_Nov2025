#!/bin/bash
#SBATCH --job-name=qc_metawrap
#SBATCH --mem=50G
#SBATCH --cpus-per-task=35
#SBATCH --array=1-24

INPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/s_merged_fastq_files"
OUTPUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/soil_metawrap/SOIL_READ_QC"
LINKDIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/soil_metawrap/metawrap_input_links"

mkdir -p "$OUTPUT"
mkdir -p "$LINKDIR"
mkdir -p logs

# Get one sample for this array task
SAMPLE_PATH=$(sed -n "${SLURM_ARRAY_TASK_ID}p" sample_list.txt)

F="${SAMPLE_PATH}_R1.fastq"
R="${SAMPLE_PATH}_R2.fastq"

BASE=$(basename "$SAMPLE_PATH")
SAMPLE="$BASE"

echo "SLURM job ID: $SLURM_JOB_ID"
echo "SLURM array task ID: $SLURM_ARRAY_TASK_ID"
echo "Processing sample: $SAMPLE"
echo "Forward: $F"
echo "Reverse: $R"

if [[ ! -f "$F" ]]; then
    echo "ERROR: Forward file not found:"
    echo "$F"
    exit 1
fi

if [[ ! -f "$R" ]]; then
    echo "ERROR: Reverse file not found:"
    echo "$R"
    exit 1
fi

# Create MetaWRAP-compatible symlinks for this sample
ln -sf "$F" "$LINKDIR/${SAMPLE}_1.fastq"
ln -sf "$R" "$LINKDIR/${SAMPLE}_2.fastq"

F_LINK="$LINKDIR/${SAMPLE}_1.fastq"
R_LINK="$LINKDIR/${SAMPLE}_2.fastq"

echo "MetaWRAP forward link: $F_LINK"
echo "MetaWRAP reverse link: $R_LINK"

metawrap read_qc \
    -1 "$F_LINK" \
    -2 "$R_LINK" \
    -t "$SLURM_CPUS_PER_TASK" \
    -o "$OUTPUT/$SAMPLE"

echo "MetaWRAP read QC completed for sample: $SAMPLE"