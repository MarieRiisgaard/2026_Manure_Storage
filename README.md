# Manure storage project

Analysis of bacterial and archaeal communities during two cow-manure storage experiments. Manure was collected from different farms and used in storage experiments at a pilot-scale facility.

**NCBI BioProject:** [PRJNA1552309](https://www.ncbi.nlm.nih.gov/bioproject/PRJNA1552309)

## Generating de-novo ASVs

This project used the usearch_ASV workflow from [KasperSkytte/snakemake_usearch](https://github.com/KasperSkytte/snakemake_usearch) to process 16S rRNA gene amplicon sequences targeting the V4 region. Taxonomic classification used the MiDAS 5.3 database.
The accompanying Bash script activates the workflow-specific Conda environment, deploys the Snakemake workflow, updates its configuration and creates a SLURM submission file. 
The config file used is uploaded in the script folder. 

## R postprocesssing 

The script:

1. Imports sequencing-derived abundance data, taxonomic assignments and sample metadata.
2. Generates heatmaps showing the relative abundances of dominant bacterial and archaeal taxa.
3. Performs principal component analysis (PCA) on Hellinger-transformed abundances to visualise changes in community composition, with paired start/end samples connected and selected taxon loadings displayed.

