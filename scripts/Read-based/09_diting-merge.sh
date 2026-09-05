#!/bin/bash
#SBATCH --job-name=merge_pathways
#SBATCH --cpus-per-task=4
#SBATCH --mem=50G
#SBATCH --output=merge_pathways_%j.out
#SBATCH --error=merge_pathways_%j.err

set -euo pipefail

# --------------------------------------------------
# CHANGE ONLY THESE TWO PATHS
# --------------------------------------------------

# Folder that contains all sample output folders
BASE_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/DITING/Output_files"

# Final folder where renamed and merged files will be saved
OUT_DIR="/mnt/scratch/wisnoskilab/dc2484/MBRACE/Sequences/November_2025/shotgun/DITING/MERGED_PATHWAYS"

# --------------------------------------------------
# Do not change below unless needed
# --------------------------------------------------

RENAMED_DIR="$OUT_DIR/renamed_tabs"
MERGED_DIR="$OUT_DIR/merged_tables"

mkdir -p "$RENAMED_DIR/pathways_relative_abundance"
mkdir -p "$RENAMED_DIR/pathways_relative_abundance_gene_level"
mkdir -p "$MERGED_DIR"

echo "Base directory: $BASE_DIR"
echo "Output directory: $OUT_DIR"
echo "Start time: $(date)"

# --------------------------------------------------
# Step 1: Copy and rename files by sample folder name
# --------------------------------------------------

echo "Copying and renaming pathway files..."

for SAMPLE_DIR in "$BASE_DIR"/*; do

    if [[ ! -d "$SAMPLE_DIR" ]]; then
        continue
    fi

    SAMPLE=$(basename "$SAMPLE_DIR")

    PATHWAY_FILE="$SAMPLE_DIR/pathways_relative_abundance.tab"
    GENE_FILE="$SAMPLE_DIR/pathways_relative_abundance_gene_level.tab"

    if [[ -f "$PATHWAY_FILE" ]]; then
        cp "$PATHWAY_FILE" "$RENAMED_DIR/pathways_relative_abundance/${SAMPLE}_pathways_relative_abundance.tab"
        echo "Copied pathway file for $SAMPLE"
    else
        echo "WARNING: Missing pathways_relative_abundance.tab for $SAMPLE"
    fi

    if [[ -f "$GENE_FILE" ]]; then
        cp "$GENE_FILE" "$RENAMED_DIR/pathways_relative_abundance_gene_level/${SAMPLE}_pathways_relative_abundance_gene_level.tab"
        echo "Copied gene-level file for $SAMPLE"
    else
        echo "WARNING: Missing pathways_relative_abundance_gene_level.tab for $SAMPLE"
    fi

done

# --------------------------------------------------
# Step 2: Merge using Python
# --------------------------------------------------

echo "Merging files..."

python << EOF

import os
import glob
import pandas as pd
from functools import reduce

renamed_dir = "$RENAMED_DIR"
merged_dir = "$MERGED_DIR"

pathway_dir = os.path.join(renamed_dir, "pathways_relative_abundance")
gene_dir = os.path.join(renamed_dir, "pathways_relative_abundance_gene_level")

# -----------------------------
# Merge pathway-level files
# -----------------------------
pathway_files = sorted(glob.glob(os.path.join(pathway_dir, "*_pathways_relative_abundance.tab")))

pathway_dfs = []

for f in pathway_files:
    sample = os.path.basename(f).replace("_pathways_relative_abundance.tab", "")

    df = pd.read_csv(f, sep="\\t")

    # First column should be pathway name
    first_col = df.columns[0]

    # Last column is abundance
    value_col = df.columns[-1]

    df = df[[first_col, value_col]]
    df.columns = ["Pathway", sample]

    pathway_dfs.append(df)

if pathway_dfs:
    merged_pathway = reduce(lambda left, right: pd.merge(left, right, on="Pathway", how="outer"), pathway_dfs)
    merged_pathway.to_csv(os.path.join(merged_dir, "merged_pathways_relative_abundance.tab"), sep="\\t", index=False)
    print("Saved merged pathway-level table")
else:
    print("No pathway-level files found")

# -----------------------------
# Merge gene-level files
# -----------------------------
gene_files = sorted(glob.glob(os.path.join(gene_dir, "*_pathways_relative_abundance_gene_level.tab")))

gene_dfs = []

for f in gene_files:
    sample = os.path.basename(f).replace("_pathways_relative_abundance_gene_level.tab", "")

    df = pd.read_csv(f, sep="\\t")

    # Expected columns:
    # Cycle, Pathway, k_number, Detail, sample abundance
    id_cols = ["Cycle", "Pathway", "k_number", "Detail"]
    value_col = df.columns[-1]

    missing_cols = [c for c in id_cols if c not in df.columns]
    if missing_cols:
        raise ValueError(f"{f} is missing columns: {missing_cols}")

    df = df[id_cols + [value_col]]
    df.columns = id_cols + [sample]

    gene_dfs.append(df)

if gene_dfs:
    merged_gene = reduce(
        lambda left, right: pd.merge(left, right, on=["Cycle", "Pathway", "k_number", "Detail"], how="outer"),
        gene_dfs
    )
    merged_gene.to_csv(os.path.join(merged_dir, "merged_pathways_relative_abundance_gene_level.tab"), sep="\\t", index=False)
    print("Saved merged gene-level table")
else:
    print("No gene-level files found")

EOF

echo "Finished time: $(date)"
echo "Merged files saved in: $MERGED_DIR"