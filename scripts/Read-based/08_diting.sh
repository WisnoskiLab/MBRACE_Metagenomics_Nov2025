#!/bin/bash
#SBATCH --nodes=1
#SBATCH --mem=100G
#SBATCH --cpus-per-task=60
#SBATCH --job-name=diting_array
#SBATCH --array=1-36
#SBATCH --output=diting_%A_%a.out
#SBATCH --error=diting_%A_%a.err

READS="/mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/CLEAN_READS"
ASSEM="/mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/ASSEMBLY_SAMPLES"
OUTBASE="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/DITING/Output_files"
SAMPLE_LIST="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/DITING/diting_sample_list.txt"

THREADS=${SLURM_CPUS_PER_TASK}
SAMPLE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

echo "Sample: $SAMPLE"
echo "Threads: $THREADS"

R1="$READS/${SAMPLE}_1.fastq"
R2="$READS/${SAMPLE}_2.fastq"
ASM="$ASSEM/${SAMPLE}.fa"

if [[ ! -f "$R1" ]]; then
    echo "ERROR: Missing R1: $R1"
    exit 1
fi

if [[ ! -f "$R2" ]]; then
    echo "ERROR: Missing R2: $R2"
    exit 1
fi

if [[ ! -f "$ASM" ]]; then
    echo "ERROR: Missing assembly: $ASM"
    exit 1
fi

WORKDIR="$OUTBASE/${SAMPLE}_diting_work"
SAMPLE_READS="$WORKDIR/reads"
SAMPLE_ASSEM="$WORKDIR/assembly"
SAMPLE_OUT="$OUTBASE/$SAMPLE"

rm -rf "$WORKDIR"
mkdir -p "$SAMPLE_READS" "$SAMPLE_ASSEM" "$SAMPLE_OUT"

ln -s "$R1" "$SAMPLE_READS/${SAMPLE}_1.fastq"
ln -s "$R2" "$SAMPLE_READS/${SAMPLE}_2.fastq"
ln -s "$ASM" "$SAMPLE_ASSEM/${SAMPLE}.fa"

echo "Reads:"
ls -lh "$SAMPLE_READS"

echo "Assembly:"
ls -lh "$SAMPLE_ASSEM"

diting.py \
  -r "$SAMPLE_READS" \
  -a "$SAMPLE_ASSEM" \
  -o "$SAMPLE_OUT" \
  -n "$THREADS"

echo "Finished: $SAMPLE"