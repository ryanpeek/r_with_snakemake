
# import libraries
import os
import glob

# set dictionaries
DATA_RAW = "data_raw"
DATA_CLEAN = "data_clean"

def checkpoint_def_get_clim_data(wildcards):
    # checkpoint_output encodes the output dir from the checkpoint rule.
    checkpoint_output = checkpoints.get_clim_data.get(**wildcards).output[0]
    global filenames
    file_names = expand("{raw}/{ct_metrics}.csv.zip", ct_metrics = glob_wildcards(os.path.join(checkpoint_output, "{ct_metrics}.csv.zip")).ct_metrics, raw = DATA_RAW)
    return file_names

rule all:
    input:
        #expand("{raw}/davis_sensor_info_by_id.csv", raw = DATA_RAW),
        "data_clean/davis_clim_data.csv.gz"

checkpoint get_clim_data:
    output: 
        dir = directory("raw"),
        meta = "data_raw/davis_sensor_info_by_id.csv"
    conda: "envs/tidyverse.yml"
    script: "src/smk2_download_davis_clim.R"

# use temp() for intermediate files, smk will keep for downstream until not needed
# then deletes.

# This rule works by itself but not in snakemake run all
rule merge_clim_data:
    input: 
        meta = expand("{raw}/davis_sensor_info_by_id.csv", raw = DATA_RAW)
    params: 
        input = "data_raw",
        output = "data_clean"
    output: "data_clean/davis_clim_data.csv.gz"
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
