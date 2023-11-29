# r_with_snakemake

snakemake workflow using R scripts to pull precipitation/climate data for Davis

## To run:

Must have `conda` installed. Make sure you are in the directory this R project lives in.

## Create the environment from yml

```
# from this file:
conda env create -f environment.yml

# or from scratch:
conda create -n precip

# to remove: conda env remove -n precip

```

## Activate the environment:

```
conda activate precip
```

## Run Snake!

Dry run: 

```
snakemake --cores 1 -p -n 
```

Real run:
```
snakemake --cores 1 -p
```

## Clean up!

`snakemake --cores -1 -p clean_all`