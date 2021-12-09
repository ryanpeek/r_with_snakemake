
# import libraries
import os
import glob

# set dictionaries
DATA_RAW = "data_raw"
DATA_CLEAN = "data_clean"

def checkpoint_def_get_clim_data(wildcards):
    # checkpoint_output encodes the output dir from the checkpoint rule.
    checkpoint_output = checkpoints.get_clim_data.get(**wildcards).output[0]
    file_names = expand("{data_raw}/{ct_metrics}.csv.zip", 
        data_raw = DATA_RAW,
        ct_metrics = glob_wildcards(os.path.join(checkpoint_output, "{ct_metrics}.csv.zip")).ct_metrics)
    return file_names

rule all:
    input:
        #expand("{data_clean}/davis_clim_data.csv.gz", data_clean = DATA_CLEAN),
        ct_files = checkpoint_def_get_clim_data,
        df_all = "data_clean/davis_clim_data.csv.gz"

rule get_metadata:
    input: "src/smk1_get_metadata_davis_clim.R"
    output: 
        csv = "{data_raw}/davis_sensor_info_by_id.csv"
    conda: "envs/tidyverse.yml"
    script: "src/smk1_get_metadata_davis_clim.R"

checkpoint get_clim_data:
    input: expand("{data_raw}/davis_sensor_info_by_id.csv", data_raw = DATA_RAW)
    output: directory("data_raw")
    conda: "envs/tidyverse.yml"
    script: "src/smk2_download_davis_clim.R"

# use temp() for intermediate files, smk will keep for downstream until not needed
# then deletes.

# This rule works by itself but not in snakemake run all
rule merge_clim_data:
    input: 
        script = "src/smk3_merge_davis_clim.R",
        metadat = expand("{data_raw}/davis_sensor_info_by_id.csv", data_raw=DATA_RAW)
    params: 
        input = "{data_raw}",
        output = "{data_clean}"
    output: "{data_clean}/davis_clim_data.csv.gz"
    conda: "envs/tidyverse.yml"
    shell:'''
    Rscript {input.script} \
        --input {params.input} \
        --outdir {params.output}
    '''

rule clean_zips:
    shell:'''
    rm -rf "{DATA_RAW}/*.csv.zip"
    '''

rule clean_all:
    shell:'''
    rm -rf {DATA_RAW}/*;
    rm -rf {DATA_CLEAN}/*.gz
    '''
