import pandas as pd
m = pd.read_csv("data_raw/davis_sensor_info_by_id.csv", header=0)
METRICS = m['metric_id'].unique().tolist()
CT_METRICS=[word for word in METRICS if word.startswith("CT")]
print(CT_METRICS)

rule all:
    input: 
        metadata = "data_raw/davis_sensor_info_by_id.csv",
        rawzips = expand("data_raw/{ct_metrics}.csv.zip", ct_metrics = CT_METRICS)

rule get_metadata:
    input: "src/smk_get_metadata_davis_clim.R"
    output: 
        csv = "data_raw/davis_sensor_info_by_id.csv"
    conda: "envs/tidyverse.yml"
    script: "src/smk_get_metadata_davis_clim.R"

rule get_clim_data:
    input:
        script = "src/smk_download_davis_clim.R",
        outdir = "data_raw/"
    output: 
        expand("data_raw/{ct_metrics}.csv.zip", ct_metrics = CT_METRICS)
    conda: "envs/tidyverse.yml"
    shell:'''
    Rscript {input.script}
    '''

rule clean:
    shell:'''
    rm -rf data_raw/*
    '''
