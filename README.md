# r_with_snakemake

snakemake workflow using R scripts to pull precipitation/climate data for Davis

## To run:

Must have `conda` and/or `mamba` installed. 

## Create the environment from yml

```
# from this file:
mamba env create -f environment.yml

# or from scratch:
mamba create -n precip
```

## Activate the environment:

```
mamba activate precip
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