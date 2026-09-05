#!/bin/bash
#SBATCH --job-name=mms90
#SBATCH --nodes=1
#SBATCH --cpus-per-task=60
#SBATCH --mem=100G
#SBATCH --array=1-36
#SBATCH --output=/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/logs/mmseqs_%A_%a.out
#SBATCH --error=/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/logs/mmseqs_%A_%a.err

set -euo pipefail

# Load MMseqs2 environment
source "/mnt/scratch/wisnoskilab/shared/bioinformatics/miniforge/etc/profile.d/conda.sh"
conda activate mmseqs2

JOBFILE_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/mmseqs_jobfiles"

TMP_BASE="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/MMSEQS/mmseqs_tmp"

mkdir -p "${TMP_BASE}"

# Read all generated jobfiles
mapfile -t JOBFILES < <(
    find "${JOBFILE_DIR}" -maxdepth 1 -type f \
        -name "*jobfile.sh" |
    sort
)

INDEX=$((SLURM_ARRAY_TASK_ID - 1))

if (( INDEX < 0 || INDEX >= ${#JOBFILES[@]} )); then
    echo "No jobfile for array task ${SLURM_ARRAY_TASK_ID}"
    exit 1
fi

JOBFILE="${JOBFILES[$INDEX]}"
JOBFILE_NAME=$(basename "${JOBFILE}")
SAMPLE="${JOBFILE_NAME%.sh}"

# Each MMseqs jobfile contains the relative temporary path "tmp".
# Running from a separate directory prevents samples from sharing it.
TASK_TMP="${TMP_BASE}/${SAMPLE}_${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}"

mkdir -p "${TASK_TMP}"
cd "${TASK_TMP}"

echo "Jobfile: ${JOBFILE}"
echo "Temporary directory: ${TASK_TMP}"
echo "MMseqs: $(command -v mmseqs)"
echo "Allocated CPUs: ${SLURM_CPUS_PER_TASK}"

if bash -e "${JOBFILE}"; then
    echo "Successfully completed: ${JOBFILE_NAME}"
    rm -rf "${TASK_TMP}"
else
    echo "MMseqs failed: ${JOBFILE_NAME}"
    echo "Temporary files retained at: ${TASK_TMP}"
    exit 1
fi