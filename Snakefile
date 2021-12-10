
# import libraries
import os
import glob

# set dictionaries
DATA_RAW = "data_raw"
DATA_CLEAN = "data_clean"

def checkpoint_def_get_clim_data(wildcards):
    # checkpoint_output encodes the output dir from the checkpoint rule.
    checkpoint_output = checkpoints.get_clim_data.get(**wildcards).output[0]
    global file_names
    file_names = expand(f"{DATA_RAW}/{{ct_metrics}}.csv.zip", ct_metrics = glob_wildcards(os.path.join(checkpoint_output, "{ct_metrics}.csv.zip")).ct_metrics)
    final_out = f"{DATA_CLEAN}/davis_clim_data.csv.gz"
    return final_out

rule all:
    input:
        #"data_clean/davis_clim_data.csv.gz"
        checkpoint_def_get_clim_data

rule get_metadata:
    input: "src/smk1_get_metadata_davis_clim.R"
    output: 
        csv = f"{DATA_RAW}/davis_sensor_info_by_id.csv"
    conda: "envs/tidyverse.yml"
    script: "src/smk1_get_metadata_davis_clim.R"

checkpoint get_clim_data:
    input: f"{DATA_RAW}/davis_sensor_info_by_id.csv"
    output: directory("raw")
    conda: "envs/tidyverse.yml"
    script: "src/smk2_download_davis_clim.R"

# use temp() for intermediate files, smk will keep for downstream until not needed
# then deletes.

# This rule works by itself but not in snakemake run all
rule merge_clim_data:
    input: 
        meta = f"{DATA_RAW}/davis_sensor_info_by_id.csv"
    params: 
        indir = DATA_RAW,
        outdir = DATA_CLEAN
    output: f"{DATA_CLEAN}/davis_clim_data.csv.gz"
    conda: "envs/tidyverse.yml"
    script: "src/smk3_merge_davis_clim.R"

#    shell:'''
#    Rscript {input.script} \
#        --input {params.input} \
#        --outdir {params.output}
#    '''

rule clean_zips:
    shell:'''
    rm -rf "{DATA_RAW}/*.csv.zip"
    '''

rule clean_all:
    shell:'''
    rm -rf {DATA_RAW}/*;
    rm -rf {DATA_CLEAN}/*.gz
    '''
