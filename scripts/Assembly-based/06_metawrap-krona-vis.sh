#!/bin/bash
#SBATCH --job-name=kraken2
#SBATCH --cpus-per-task=100
#SBATCH --mem=1000G
#SBATCH --output=kraken_met.out
#SBATCH --error=kraken_met.err


OUT="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/Metawrap/KRAKEN/KRAKEN_OUTPUT"

DB="/mnt/scratch/wisnoskics/shared/databases/Kraken_GTDBv226"

CONFIG=$(which config-metawrap)

if [[ -z "$CONFIG" ]]; then
    echo "ERROR: config-metawrap was not found."
    exit 1
fi

source "$CONFIG"

echo "MetaWRAP scripts folder: $SOFT"
echo "Kraken2 database: $DB"
echo "Output folder: $OUT"

if [[ ! -d "$OUT" ]]; then
    echo "ERROR: Output directory does not exist:"
    echo "$OUT"
    exit 1
fi

if [[ ! -d "$DB" ]]; then
    echo "ERROR: Kraken2 database directory does not exist:"
    echo "$DB"
    exit 1
fi

if [[ ! -f "$SOFT/kraken2_translate.py" ]]; then
    echo "ERROR: Missing:"
    echo "$SOFT/kraken2_translate.py"
    exit 1
fi

if [[ ! -f "$SOFT/kraken_to_krona.py" ]]; then
    echo "ERROR: Missing:"
    echo "$SOFT/kraken_to_krona.py"
    exit 1
fi

if ! command -v ktImportText >/dev/null 2>&1; then
    echo "ERROR: ktImportText was not found."
    echo "KronaTools is not installed or is not available in PATH."
    exit 1
fi

# -------------------------------------------------------------------
# Translate MetaWRAP .krak2 outputs to taxonomy-formatted .kraken2 files
# -------------------------------------------------------------------

krak2_files=("$OUT"/*.krak2)

if (( ${#krak2_files[@]} == 0 )); then
    echo "ERROR: No .krak2 files found in:"
    echo "$OUT"
    exit 1
fi

for file in "${krak2_files[@]}"; do
    output="${file%.krak2}.kraken2"

    if [[ -s "$output" ]]; then
        echo "Already exists, skipping: $(basename "$output")"
        continue
    fi

    echo "Translating: $(basename "$file")"

    python "$SOFT/kraken2_translate.py" \
        "$DB" \
        "$file" \
        "$output"

    if [[ ! -s "$output" ]]; then
        echo "ERROR: Failed to generate:"
        echo "$output"
        exit 1
    fi
done

# -------------------------------------------------------------------
# Convert translated Kraken files to Krona input format
# -------------------------------------------------------------------

translated_files=("$OUT"/*.kraken2)

if (( ${#translated_files[@]} == 0 )); then
    echo "ERROR: No translated .kraken2 files were found."
    exit 1
fi

for file in "${translated_files[@]}"; do
    krona_output="${file%.kraken2}.krona"

    if [[ -s "$krona_output" ]]; then
        echo "Already exists, skipping: $(basename "$krona_output")"
        continue
    fi

    echo "Creating Krona input: $(basename "$file")"

    python "$SOFT/kraken_to_krona.py" \
        "$file" \
        > "$krona_output"

    if [[ ! -s "$krona_output" ]]; then
        echo "ERROR: Failed to generate:"
        echo "$krona_output"
        exit 1
    fi
done

# -------------------------------------------------------------------
# Create combined interactive Krona HTML
# -------------------------------------------------------------------

krona_files=("$OUT"/*.krona)

if (( ${#krona_files[@]} == 0 )); then
    echo "ERROR: No .krona files were generated."
    exit 1
fi

echo "Creating combined Krona visualization..."

ktImportText \
    -o "$OUT/kronagram.html" \
    "${krona_files[@]}"

if [[ ! -s "$OUT/kronagram.html" ]]; then
    echo "ERROR: kronagram.html was not generated."
    exit 1
fi

echo "Krona visualization successfully created:"
echo "$OUT/kronagram.html"