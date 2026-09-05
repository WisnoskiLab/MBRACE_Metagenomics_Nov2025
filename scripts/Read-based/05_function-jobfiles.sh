#!/bin/bash
#SBATCH --job-name=mm_90
#SBATCH --nodes=1
#SBATCH --cpus-per-task=60
#SBATCH --mem=300G
#SBATCH --output=mm90.out

set -euo pipefail

source "/mnt/scratch/wisnoskilab/shared/bioinformatics/miniforge/etc/profile.d/conda.sh"
conda activate megan_perl

unset PERL5LIB
hash -r

WORK_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS"

SCRIPT="${WORK_DIR}/run_TaxonomyFunctionSearchMegan.pl"

# This must be the actual MMseqs database prefix
DB="/mnt/scratch/wisnoskics/shared/databases/MMSeqs2/MMSEQs_UNIREF90/UniRef90_2026-07"

READ_DIR="/mnt/scratch/wisnoskics/dc2484/November_2025/Shotgun/CLEAN_READS_CAT"

OUT_DIR="${WORK_DIR}/MMSEQS_OUT_90"
LINK_DIR="${WORK_DIR}/mmseqs_input_links"
JOBFILE_DIR="${WORK_DIR}/mmseqs_jobfiles"

THREADS_PER_JOB=60

mkdir -p "${OUT_DIR}" "${LINK_DIR}" "${JOBFILE_DIR}"

rm -f "${LINK_DIR}"/*
rm -f "${JOBFILE_DIR}"/*jobfile.sh
rm -f "${JOBFILE_DIR}/jobfiles.list"

mapfile -t READS < <(
    find "${READ_DIR}" -maxdepth 1 -type f \
        \( -name "*.fastq" -o \
           -name "*.fq" -o \
           -name "*.fastq.gz" -o \
           -name "*.fq.gz" \) |
    sort
)

if (( ${#READS[@]} == 0 )); then
    echo "No FASTQ files found in ${READ_DIR}"
    exit 1
fi

# Create symlinks whose names contain no underscores
for READ in "${READS[@]}"; do

    FILE=$(basename "${READ}")

    SAMPLE="${FILE%.fastq.gz}"
    SAMPLE="${SAMPLE%.fq.gz}"
    SAMPLE="${SAMPLE%.fastq}"
    SAMPLE="${SAMPLE%.fq}"

    EXT="${FILE#${SAMPLE}}"

    # W_PAS_ST9_2025NOV_02 becomes W-PAS-ST9-2025NOV-02
    SAFE_SAMPLE="${SAMPLE//_/-}"

    ln -sfn "${READ}" "${LINK_DIR}/${SAFE_SAMPLE}${EXT}"

done

mapfile -t SAFE_READS < <(
    find "${LINK_DIR}" -maxdepth 1 -type l |
    sort
)

echo "Input FASTQ files: ${#READS[@]}"
echo "Temporary input links: ${#SAFE_READS[@]}"

cd "${JOBFILE_DIR}"

perl "${SCRIPT}" \
    --mapmethod mmseqs \
    --db "${DB}" \
    -p "${THREADS_PER_JOB}" \
    -o "${OUT_DIR}" \
    "${SAFE_READS[@]}"

find "${JOBFILE_DIR}" -maxdepth 1 -type f -name "*jobfile.sh" \
    -printf "%f\n" |
    sort > "${JOBFILE_DIR}/jobfiles.list"

NUM_JOBFILES=$(wc -l < "${JOBFILE_DIR}/jobfiles.list")

echo "Jobfiles generated: ${NUM_JOBFILES}"
echo "Jobfiles directory: ${JOBFILE_DIR}"

if (( NUM_JOBFILES != ${#READS[@]} )); then
    echo "ERROR: Expected ${#READS[@]} jobfiles but found ${NUM_JOBFILES}."
    exit 1
fi