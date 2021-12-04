import os
import glob

OUTDIR = "data_raw"

def checkpoint_def_get_clim_data(wildcards):
    # checkpoint_output encodes the output dir from the checkpoint rule.
    checkpoint_output = checkpoints.get_clim_data.get(**wildcards).output[0]
    
    # one option I found:
    #METRICS = set()  # a set is like a list, but only stores unique values
    #for METRIC in os.listdir(checkpoint_output):
    #        METRICS.add(METRIC)
    #ct_metrics = ["{OUTDIR}/" + METRIC + ".csv.zip" for METRIC in METRICS]
    #return(ct_metrics)
    file_names = expand("{outdir}/{ct_metrics}.csv.zip", ct_metrics = glob_wildcards(os.path.join(checkpoint_output, "{ct_metrics}.csv.zip")).ct_metrics, outdir = OUTDIR)
    return file_names

rule all:
    input:
        "data_raw/davis_sensor_info_by_id.csv",
        checkpoint_def_get_clim_data
        

rule get_metadata:
    input: "src/smk_get_metadata_davis_clim.R"
    output: 
        csv = "data_raw/davis_sensor_info_by_id.csv"
    conda: "envs/tidyverse.yml"
    script: "src/smk_get_metadata_davis_clim.R"

# add checkpoints here or below, uses to build dag
checkpoint get_clim_data:
    input:
        script = "src/smk_download_davis_clim.R"
    output: directory("outdir")
    conda: "envs/tidyverse.yml"
    shell:'''
    Rscript {input.script}
    '''
# use temp() for intermediate files, smk will keep for downstream until not needed
# then deletes.

rule clean_zips:
    shell:'''
    rm -rf {OUTDIR}/*.csv.zip
    '''

rule clean_meta:
    shell:'''
    rm -rf {OUTDIR}/davis_sensor_info_by_id.csv
    '''