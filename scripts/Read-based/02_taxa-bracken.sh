#!/bin/bash
#SBATCH --job-name=bracken
#SBATCH --nodes=1
#SBATCH --cpus-per-task=15
#SBATCH --mem=100G
#SBATCH --array=1-36
#SBATCH --output=bracken_%A_%a.out
#SBATCH --error=bracken_%A_%a.err

DB="/mnt/scratch/wisnoskics/shared/databases/Kraken_GTDBv226"

REPORT_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/KRAKEN/KRAKEN_OUTPUT/KRAKEN_REPORTS"

OUTPUT_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/KRAKEN/BRACKEN_OUTPUT"


mkdir -p "${OUTPUT_DIR}"

mapfile -t REPORTS < <(
    find "${REPORT_DIR}" -maxdepth 1 -type f \
        \( -name "*.kraken2.report" -o -name "*.kreport" \) \
        ! -name "*bracken*" |
    sort
)

INDEX=$((SLURM_ARRAY_TASK_ID - 1))

if (( INDEX >= ${#REPORTS[@]} )); then
    echo "No Kraken report found for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

REPORT="${REPORTS[$INDEX]}"
FILENAME=$(basename "${REPORT}")

if [[ "${FILENAME}" == *.kraken2.report ]]; then
    SAMPLE="${FILENAME%.kraken2.report}"
elif [[ "${FILENAME}" == *.kreport ]]; then
    SAMPLE="${FILENAME%.kreport}"
else
    SAMPLE="${FILENAME%.*}"
fi

if [[ ! -f "${DB}/database150mers.kmer_distrib" ]]; then
    echo "Missing Bracken distribution file:"
    echo "${DB}/database150mers.kmer_distrib"
    exit 1
fi

echo "Sample: ${SAMPLE}"
echo "Input report: ${REPORT}"

declare -A LEVELS=(
    [phylum]="P"
    [class]="C"
    [order]="O"
    [family]="F"
    [genus]="G"
)

for LEVEL_NAME in phylum class order family genus
do
    LEVEL_CODE="${LEVELS[$LEVEL_NAME]}"
    LEVEL_DIR="${OUTPUT_DIR}/${LEVEL_NAME^^}"

    mkdir -p "${LEVEL_DIR}"

    echo "Running ${LEVEL_NAME} level for ${SAMPLE}"

    bracken \
        -d "${DB}" \
        -i "${REPORT}" \
        -o "${LEVEL_DIR}/${SAMPLE}.${LEVEL_NAME}.bracken" \
        -w "${LEVEL_DIR}/${SAMPLE}.${LEVEL_NAME}.bracken.kreport" \
        -r 150 \
        -l "${LEVEL_CODE}" \
        -t 10

    if [[ $? -ne 0 ]]; then
        echo "Bracken failed at ${LEVEL_NAME} level for ${SAMPLE}"
        exit 1
    fi
done

echo "Completed all taxonomic levels for ${SAMPLE}"