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
        metdat = expand("{outdir}/davis_sensor_info_by_id.csv", outdir = OUTDIR),
        ct_files = checkpoint_def_get_clim_data,
        df_all = "data_clean/davis_clim_data.csv.gz"

rule get_metadata:
    input: "src/smk_get_metadata_davis_clim.R"
    output: 
        csv = "{outdir}/davis_sensor_info_by_id.csv"
    conda: "envs/tidyverse.yml"
    script: "src/smk_get_metadata_davis_clim.R"

# add checkpoints here or below, uses to build dag
checkpoint get_clim_data:
    input:
        script = "src/smk_download_davis_clim.R"
    params: 
        outdir = "data_raw"
    output: directory("outdir")
    conda: "envs/tidyverse.yml"
    shell:'''
    Rscript {input.script} \
        --outdir {params.outdir}
    '''
# use temp() for intermediate files, smk will keep for downstream until not needed
# then deletes.

# This breaks or doesn't work
#rule merge_clim_data:
#    input:
#        script = "src/smk_merge_davis_clim.R",
#        raw = directory("outdir")
#    params: 
#        input = "data_raw",
#       output = "data_clean"
#    output: "data_clean/davis_clim_data.csv.gz"
#    conda: "envs/tidyverse.yml"
#    shell:'''
#    Rscript {input.script} \
#        --input {params.input} \
#        --outdir {params.output}
#    '''

rule clean_zips:
    shell:'''
    rm -rf {OUTDIR}/*.csv.zip
    '''

rule clean_all:
    shell:'''
    rm -rf {OUTDIR}/*
    '''