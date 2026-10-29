#!/usr/bin/env bash
set -e

# Need to work in conda env. with snakemake to deploy workflow
    ## Depending on workflow a seperate conda needs to be activate (see environment.yml in the relevant git-project)


# --- Edit these settings ---
workflow="usearch_ASV"                 # usearch_ASV, savont, nanopore_16Samp
run="test_run"
primer="V4"                           # V1V8, V4, OPR, V1V3
input_seq="path/to/input_sequneces"
base="base_direktory"
db="/databases/midas/MiDAS5.3_20240320"  # Path to the taxonomic database
# -------------------------------


# --- Select conda environment ---
CONDA_ACTIVATE="/usr/local/Miniforge3-25.3.1-0-Linux-x86_64/etc/profile.d/conda.sh"

case $workflow in
    usearch_ASV)    ENV_NAME="snakemake_usearch" ;;
    savont)         ENV_NAME="snakemake_savont" ;;
    nanopore_16Samp) ENV_NAME="nanopore_16samp" ;;
esac

source ${CONDA_ACTIVATE}
conda activate ${ENV_NAME}

# --- Select workflow and primers ---
case $workflow in
    usearch_ASV)    repo="KasperSkytte/snakemake_usearch" ;;
    savont)         repo="KasperSkytte/snakemake_savont" ;;
    nanopore_16Samp) repo="cmc-aau/nanopore_16Samp" ;;
esac

case $primer in
    V1V8) FWD="AGRGTTYGATYMTGGCTCAG"; REV="TGYACWCACCGCCCGTC"; MIN=1031; MAX=1716 ;;
    V4)   FWD="GTGYCAGCMGCCGCGGTAA"; REV="ATTAGAWACCCBDGNTAGTCC"; MIN=190; MAX=316 ;;
    OPR)  FWD="AGRGTTYGATYMTGGCTCAG"; REV="GTTTGGCACCTCGATGTCG"; MIN=3281; MAX=5463 ;;
    V1V3) FWD="AGRGTTYGATYMTGGCTCAG"; REV="CCAGCAGCCGCGGTAAT"; MIN=376; MAX=624 ;;
esac

# --- Create a new run ---
run_folder="$base/$workflow/$run"
if [[ -e $run_folder || -L $run_folder ]]; then
    echo "Folder already exists: $run_folder"
    exit 1
fi

input_seq=$(cd "$input_seq" && pwd)
mkdir -p "$base/$workflow"
mkdir "$run_folder"

# --- Deploy workflow ---
snakedeploy deploy-workflow "https://github.com/$repo" \
    --target-dir "$run_folder" --branch main --force
cd "$run_folder"

# --- Update config ---
config="config/config.yaml"
set_config() {
    local key=$1 value=$2

    case "$value" in
        True|False|[0-9]*) ;;
        *) value="\"$value\"" ;;
    esac

    sed -i "s|^$key:.*|$key: $value|" "$config"
}
set_config input_dir "$input_seq"

if [[ $workflow == nanopore_16Samp ]]; then
    set_config db_fasta "$db/FLASVs.fa"
    set_config db_tax "$db/tax_complete_qiime.txt"
    echo "This workflow does not trim primers."
else
    set_config db_sintax "$db/FLASVs_w_sintax.fa"
    if [[ $workflow == usearch_ASV ]]; then
        set_config input_dir "$input_seq"
        set_config db_sintax "$db/FLASVs_w_sintax.fa"
        set_config filtlong_args "--min_length 1"
        set_config unoise_minsize 4
        set_config primers "$FWD...$REV_RC -m $MIN -M $MAX"
    else
        set_config cutadapt_args "-g $FWD...$REV -m $MIN -M $MAX --revcomp --discard-untrimmed"
    fi
fi



# --- Create SLURM submission file ---
cat > "$run_folder/slurm_submit.sbatch" <<EOF
#!/bin/bash
#SBATCH --job-name=$run
#SBATCH --output=$run_folder/job_%j_%x.out
#SBATCH --cpus-per-task=2
#SBATCH --time=0-12:00:00
#SBATCH --mem=2G
#SBATCH --account=phn

set -e
cd "$run_folder"

# --- Select conda environment ---
CONDA_ACTIVATE="/usr/local/Miniforge3-25.3.1-0-Linux-x86_64/etc/profile.d/conda.sh"

case $workflow in
    usearch_ASV)    ENV_NAME="snakemake_usearch" ;;
    savont)         ENV_NAME="snakemake_savont" ;;
    nanopore_16Samp) ENV_NAME="nanopore_16samp" ;;
esac

source ${CONDA_ACTIVATE}
conda activate ${ENV_NAME}

snakemake \\
  --executor slurm \\
  --jobs 96 \\
  --keep-going \\
  --rerun-incomplete \\
  --default-resources slurm_account=phn runtime=480 mem_mb=16000
EOF

echo "Submit with: sbatch \"$run_folder/slurm_submit.sbatch\""

