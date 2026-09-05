#!/bin/bash
#SBATCH --job-name=kraken2
#SBATCH --cpus-per-task=100
#SBATCH --mem=1000G
#SBATCH --output=kraken_met.out
#SBATCH --error=kraken_met.err

# Load MetaWRAP config
source $(which config-metawrap)

CLEAN_READS="/mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/CLEAN_READS"
OUTPUT_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/KRAKEN/KRAKEN_OUTPUT"
ASM="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/ASSEMBLY-MEGAHIT/ASSEMBLY/megahit/final.contigs.fa"

mkdir -p "$OUTPUT_DIR"

echo "PIPES: $PIPES"
echo "KRAKEN2_DB: $KRAKEN2_DB"
echo "Kraken2 script: $PIPES/kraken2.sh"
echo "Threads: $SLURM_CPUS_PER_TASK"

# Check files/folders
if [[ ! -f "$PIPES/kraken2.sh" ]]; then
    echo "ERROR: kraken2.sh not found: $PIPES/kraken2.sh"
    exit 1
fi

if [[ ! -d "$CLEAN_READS" ]]; then
    echo "ERROR: CLEAN_READS folder not found: $CLEAN_READS"
    exit 1
fi

if [[ ! -f "$ASM" ]]; then
    echo "ERROR: assembly file not found: $ASM"
    exit 1
fi

if [[ ! -d "$KRAKEN2_DB" ]]; then
    echo "ERROR: KRAKEN2_DB folder not found: $KRAKEN2_DB"
    exit 1
fi

echo "Checking Kraken2 DB files:"
ls -lh "$KRAKEN2_DB"/hash.k2d "$KRAKEN2_DB"/opts.k2d "$KRAKEN2_DB"/taxo.k2d

echo "Checking input reads:"
ls "$CLEAN_READS"/*_1.fastq | head

echo "Checking assembly:"
ls -lh "$ASM"

# Run MetaWRAP Kraken2 wrapper
bash "$PIPES/kraken2.sh" \
  -o "$OUTPUT_DIR" \
  -t "$SLURM_CPUS_PER_TASK" \
  -s 1000000 \
  "$CLEAN_READS"/*_1.fastq \
  "$ASM"

echo "Finished Kraken2 MetaWRAP wrapper"
echo "End time: $(date)"