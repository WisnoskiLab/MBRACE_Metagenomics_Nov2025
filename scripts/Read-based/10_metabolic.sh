#!/bin/bash
#SBATCH --job-name=metabolic_sep
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=30
#SBATCH --mem=80G
#SBATCH --array=1-36%8
#SBATCH --output=metabolic_sep_%A_%a.out
#SBATCH --error=metabolic_sep_%A_%a.err

set -euo pipefail

module load R

# ================= PATHS =================

METABOLIC_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/METABOLIC"

# Original successful METABOLIC-C run
BASE_OUT="${METABOLIC_DIR}/METABOLIC-C"

# Original 339 MAG folder
GENOME_SRC="/mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/MAGs_fasta"

# Folder containing ALL paired reads
READ_DIR="/mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/CLEAN_READS_COMPRESS"

# Separate outputs will go here
OUT_ROOT="${METABOLIC_DIR}/METABOLIC-C_BY_SAMPLE"

# ================= ENVIRONMENT =================

source /mnt/scratch/wisnoskilab/shared/bioinformatics/miniforge/etc/profile.d/conda.sh
conda activate metabolic_v4

export POPPLER=/mnt/scratch/wisnoskilab/shared/bioinformatics/poppler
export PKG_CONFIG_PATH=$POPPLER/lib64/pkgconfig:$PKG_CONFIG_PATH
export LD_LIBRARY_PATH=$POPPLER/lib64:$LD_LIBRARY_PATH
export PATH=$POPPLER/bin:$PATH

mkdir -p "$OUT_ROOT"

# ================= GET SAMPLE =================

mapfile -t R1_FILES < <(
    find "$READ_DIR" -maxdepth 1 -type f -name "*_R1.fastq.gz" | sort
)

INDEX=$((SLURM_ARRAY_TASK_ID - 1))

if [[ $INDEX -ge ${#R1_FILES[@]} ]]; then
    echo "ERROR: Array task ${SLURM_ARRAY_TASK_ID} has no corresponding R1 file"
    exit 1
fi

R1="${R1_FILES[$INDEX]}"
SAMPLE=$(basename "$R1" "_R1.fastq.gz")
R2="${READ_DIR}/${SAMPLE}_R2.fastq.gz"

if [[ ! -f "$R2" ]]; then
    echo "ERROR: R2 missing:"
    echo "$R2"
    exit 1
fi

echo "=========================================="
echo "Sample:  $SAMPLE"
echo "R1:      $R1"
echo "R2:      $R2"
echo "Threads: $SLURM_CPUS_PER_TASK"
echo "Node:    $(hostname)"
echo "=========================================="

# ================= SAMPLE OUTPUT =================

OUTDIR="${OUT_ROOT}/${SAMPLE}"
mkdir -p "$OUTDIR"

# Reuse expensive annotation intermediates from original run
if [[ ! -e "${OUTDIR}/intermediate_files" ]]; then
    ln -s "${BASE_OUT}/intermediate_files" \
          "${OUTDIR}/intermediate_files"
fi

# METABOLIC requires R1,R2 on one comma-separated line
printf "%s,%s\n" "$R1" "$R2" > "${OUTDIR}/reads.txt"

# ================= ISOLATED MAG WORKSPACE =================
#
# Important:
# METABOLIC second-run creates total.faa inside -in-gn.
# Therefore each parallel job gets its own genome workspace.

GENOME_WORK="${OUTDIR}/genome_workspace"
mkdir -p "$GENOME_WORK"

find "$GENOME_SRC" -maxdepth 1 -type f \
    \( -name "*.fasta" -o -name "*.faa" -o -name "*.gene" \) \
    ! -name "total.faa" \
    ! -name "faa.total" \
    -exec ln -sf {} "$GENOME_WORK/" \;

# Make sure annotations exist
FAA_COUNT=$(find "$GENOME_WORK" -maxdepth 1 -name "*.faa" | wc -l)
GENE_COUNT=$(find "$GENOME_WORK" -maxdepth 1 -name "*.gene" | wc -l)

echo "FAA files:  $FAA_COUNT"
echo "Gene files: $GENE_COUNT"

if [[ "$FAA_COUNT" -eq 0 || "$GENE_COUNT" -eq 0 ]]; then
    echo "ERROR: .faa or .gene files are missing."
    exit 1
fi

# ================= RUN METABOLIC =================

cd "$METABOLIC_DIR"

perl /mnt/scratch/wisnoskilab/shared/bioinformatics/METABOLIC/METABOLIC/METABOLIC-C.2nd_run.pl \
    -in-gn "$GENOME_WORK" \
    -r "${OUTDIR}/reads.txt" \
    -o "$OUTDIR" \
    -t "$SLURM_CPUS_PER_TASK" \
    -p meta \
    -kofam-db full \
    -m-cutoff 0.75 \
    -rt metaG \
    -st illumina \
    -tax phylum \
    -2nd-run true \
    -2nd-run-suffix "$SAMPLE"

# ================= CHECK RESULT =================

DEPTH="${OUTDIR}/All_gene_collections_mapped.depth.${SAMPLE}.txt"

echo
echo "========== FINAL CHECK =========="

if [[ -s "$DEPTH" ]]; then
    echo "SUCCESS: $SAMPLE"
    echo "Depth file:"
    ls -lh "$DEPTH"
    echo "Lines:"
    wc -l "$DEPTH"
else
    echo "ERROR: depth file missing or empty for $SAMPLE"
    exit 1
fi

echo "Output:"
echo "$OUTDIR"
echo "================================="