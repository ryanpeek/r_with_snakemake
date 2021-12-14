
# import libraries
import os
import glob

# set dictionaries
DATA_RAW = "data_raw"
DATA_CLEAN = "data_clean"
ZIPS = "data_raw/zips"

def checkpoint_def_get_clim_data(wildcards):
    # checkpoint_output encodes the output dir from the checkpoint rule.
    checkpoint_output = checkpoints.get_clim_data.get(**wildcards).output[0]
    file_names = expand(f"{ZIPS}/{{ct_metrics}}.csv.zip", ct_metrics = glob_wildcards(os.path.join(checkpoint_output, "{ct_metrics}.csv.zip")).ct_metrics)
    return file_names

rule all:
    input:
        "figures/monthly_weekly_precip_davis_ca_updated.png"
        #f"{DATA_CLEAN}/davis_clim_data.csv.gz"

rule get_metadata:
    input: "src/smk1_get_metadata_davis_clim.R"
    output: 
        csv = f"{DATA_RAW}/davis_sensor_info_by_id.csv"
    conda: "envs/tidyverse.yml"
    script: "src/smk1_get_metadata_davis_clim.R"

checkpoint get_clim_data:
    input: f"{DATA_RAW}/davis_sensor_info_by_id.csv"
    output: directory(f"{ZIPS}")
    conda: "envs/tidyverse.yml"
    script: "src/smk2_download_davis_clim.R"

# use temp() for intermediate files, smk will keep for downstream until not needed
# then deletes.

# merge data
rule merge_clim_data:
    input: 
        meta = f"{DATA_RAW}/davis_sensor_info_by_id.csv",
        checkpoint = checkpoint_def_get_clim_data
    params: 
        indir = ZIPS,
        outdir = DATA_CLEAN
    output: f"{DATA_CLEAN}/davis_clim_data.csv.gz"
    conda: "envs/tidyverse.yml"
    script: "src/smk3_merge_davis_clim.R"

# viz data
rule viz_data:
    input: f"{DATA_CLEAN}/davis_clim_data.csv.gz"
    output: "figures/monthly_weekly_precip_davis_ca_updated.png"
    conda: "envs/tidyverse.yml"
    script: "src/smk4_visualize.R"


rule clean_zips:
    shell:'''
    rm -rf "{ZIPS}/*.csv.zip"
    '''

rule clean_all:
    shell:'''
    rm -rf {ZIPS};
    rm -rf {DATA_CLEAN}
    '''
