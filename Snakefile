OUTDIR = "data_raw"

def checkpoint_def_get_clim_data(wildcards):
    # checkpoint_output encodes the output dir from the checkpoint rule.
    checkpoint_output = checkpoints.get_clim_data.get(**wildcards).output[0]
    # can return global here with 'global CT_METRICS'
    file_names = expand("{outdir}/{ct_metrics}.csv.zip", ct_metrics = glob_wildcards(os.path.join(checkpoint_output, "{ct_metrics}.csv.zip")).ct_metrics, outdir = OUTDIR)
    return file_names

rule all:
    input:
        checkpoint_def_get_clim_data
            
#expand("{outdir}/davis_sensor_info_by_id.csv", outdir = OUTDIR)    

rule get_metadata:
    output: 
        csv = expand("{outdir}/davis_sensor_info_by_id.csv", outdir=OUTDIR)
    conda: "envs/tidyverse.yml"
    script: "src/smk_get_metadata_davis_clim.R"

# add checkpoints here or below, uses to build dag
checkpoint get_clim_data:
    input:
        script = "src/smk_download_davis_clim.R"
    output: directory("{outdir}")
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
