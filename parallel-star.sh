#!/bin/bash

# A bash script for parallel batch alignment using STAR.
# Aligns all samples listed in a text file by processing
# N samples in parallel at a time. 

# The number of STAR runs to perform in parallel
PARALLEL_ALIGNMENTS=4
# STAR threads to be used (value for --runThreadN)
STAR_THREADS=8
# Location of the samples list file. File is assume to contain a
# single sample name per line.
SAMPLES_FILE="/path/to/your/samples.txt"
# Location of sequence files
R_FILE_PATH="/path/to/your/sequences/"
# Location to which the output is generated
OUTPUT_PATH="/path/to/your/output/"
# Directory where the genome indices are located
INDEX_FILE="/path/to/your/indices/"

# Count the number of non-empty lines in the sample file.
N_SAMPLES=$(cat $SAMPLES_FILE | sed '/^\s*#/d;/^\s*$/d' | wc -l)

# Loop through all lines in the sample file. Lines are assumed to
# contain the name of the sample (the part before e.g. _R1.fastaq).
for i in $(seq 1 $N_SAMPLES);
do
    # Read the name of the sample from the i-th line.
    SAMPLE=$(awk "NR==$i" $SAMPLES_FILE)
    # Form paths to the current pair of sequence files
    R1=${R_FILE_PATH}/${SAMPLE}_R1.fastq
    R2=${R_FILE_PATH}/${SAMPLE}_R2.fastq
    # Create a folder for the outpus
    mkdir -p ${OUTPUT_PATH}/${SAMPLE}_2pass/

    # Start parallel STAR runs. Variable PARALLEL_ALIGNMENTS defines the
    # number of STAR runs executed in parallel.
    sem -j $PARALLEL_ALIGNMENTS \
    STAR \
    --runThreadN $STAR_THREADS \
    --genomeDir $INDEX_FILE \
    --readFilesIn $R1 $R2 \
    --readFilesCommand gunzip -c \
    --outFileNamePrefix ${OUTPUT_PATH}/${SAMPLE}_2pass/ \
    --outSAMstrandField intronMotif \
    --outFilterIntronMotifs RemoveNoncanonical \
    --alignEndsType EndToEnd \
    --outSAMtype BAM SortedByCoordinate ";"

done
# Wait until all the samples are aligned
sem --wait --will-cite
