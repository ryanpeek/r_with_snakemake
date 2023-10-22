# import libraries
import os
import glob

rule all:
    input:
        'figures/precip_by_month_last_20yrs_current.png',
        'data_clean/davis_clim_data.csv.gz', 
        #'figures/precip_by_month_1981_current.png',
        #'figures/precip_by_week_1981_current.png'

rule get_metadata:
    input: 'src/smk1_get_metadata_davis_clim.R'
    output: 
        csv = 'data_raw/davis_sensor_info_by_id.csv'
    conda: 'envs/tidyverse.yml'
    script: 'src/smk1_get_metadata_davis_clim.R'

rule get_clim_data:
    input: 'data_raw/davis_sensor_info_by_id.csv'
    output: directory('zips')
    conda: 'envs/tidyverse.yml'
    script: 'src/smk2_download_davis_clim.R'

# use temp() for intermediate files, smk will keep for downstream until not needed
# then deletes.

# merge data
rule merge_clim_data:
    input: 
        meta = 'data_raw/davis_sensor_info_by_id.csv'
    params: 
        indir = 'data_raw/zips',
        outdir = 'data_clean'
    output: 'data_clean/davis_clim_data.csv.gz'
    conda: 'envs/tidyverse.yml'
    script: 'src/smk3_merge_davis_clim.R'

# viz data
rule viz_data:
    input: 'data_clean/davis_clim_data.csv.gz'
    output: 'figures/precip_by_month_last_20yrs_current.png'
    conda: 'envs/tidyverse.yml'
    script: 'src/smk4_visualize.R'


rule clean_zips:
    shell:'''
    rm -rf data_raw/zips/*.csv.zip
    '''

rule clean_all:
    shell:'''
    rm -rf data_raw/zips;
    rm -rf data_clean;
    rm -rf figures/*png
    '''
