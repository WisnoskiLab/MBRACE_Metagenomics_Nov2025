#!/bin/bash
#SBATCH --job-name=mmseqs_U100
#SBATCH --nodes=1
#SBATCH --array=1-36
#SBATCH --cpus-per-task=5
#SBATCH --mem=50G
#SBATCH --output=tophit.out

set -euo pipefail

FILES="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/MMSEQS_OUT_90"
OUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/mmseqs_out_tophit_Un90"
SCRIPT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/pick_uniref_top_hit.py"
LOGDIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/logs-2"

mkdir -p "$OUT" "$LOGDIR"

# Collect all .m8 files, including files inside subdirectories
mapfile -t M8_FILES < <(
    find "$FILES" -type f -name "*.m8" | sort
)

N_FILES=${#M8_FILES[@]}
INDEX=$((SLURM_ARRAY_TASK_ID - 1))

if (( N_FILES == 0 )); then
    echo "ERROR: No .m8 files found in:"
    echo "$FILES"
    exit 1
fi

if (( INDEX < 0 || INDEX >= N_FILES )); then
    echo "ERROR: Array task ${SLURM_ARRAY_TASK_ID} is outside range 1-${N_FILES}"
    exit 1
fi

M8_FILE="${M8_FILES[$INDEX]}"
M8_NAME=$(basename "$M8_FILE")
EXPECTED_OUT="$OUT/${M8_NAME}-parsed.txt"

echo "Task: ${SLURM_ARRAY_TASK_ID}/${N_FILES}"
echo "Input: $M8_FILE"
echo "Expected output: $EXPECTED_OUT"

# Skip successfully completed files
# Zero-byte files are not skipped and will be rerun
if [[ -s "$EXPECTED_OUT" ]]; then
    echo "Already completed. Skipping."
    exit 0
fi

# Remove an incomplete zero-byte output
if [[ -e "$EXPECTED_OUT" && ! -s "$EXPECTED_OUT" ]]; then
    echo "Removing incomplete output:"
    echo "$EXPECTED_OUT"
    rm -f "$EXPECTED_OUT"
fi

# The Python script accepts a directory, not an individual file.
# Create a temporary directory containing only this task's .m8 file.
TASK_DIR="${SLURM_TMPDIR:-/tmp}/tophit_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"

mkdir -p "$TASK_DIR"

cleanup() {
    rm -rf "$TASK_DIR"
}

trap cleanup EXIT

ln -s "$M8_FILE" "$TASK_DIR/$M8_NAME"

python "$SCRIPT" \
    --unirefm8Dir "$TASK_DIR" \
    --output_path "$OUT"

# Confirm output was created successfully
if [[ ! -s "$EXPECTED_OUT" ]]; then
    echo "ERROR: Output was not created or is empty:"
    echo "$EXPECTED_OUT"
    exit 1
fi

echo "Successfully completed:"
echo "$EXPECTED_OUT"