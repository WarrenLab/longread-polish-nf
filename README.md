# longread-polish-nf
Nextflow pipeline for polishing an assembly with long reads and racon

## Introduction
Polishing a genome assembly with racon is pretty simple, except that it can take
a while on large genomes and so you might want to distribute the tasks into
multiple jobs on a cluster or the cloud. This pipeline does that distribution
for you.

## Requirements
### Data
* Long reads
* An assembly created from those long reads

### Nextflow
* [nextflow](https://www.nextflow.io/) — can be installed with the command
  `curl -s https://get.nextflow.io | bash`

### Other software
* [racon](https://github.com/lbcb-sci/racon)
* [minimap2](https://github.com/lh3/minimap2)
* [samtools](http://www.htslib.org/)

This pipeline is set up to use mamba to create an environment with these three
programs in it, but you can always install them yourself or use modules. See
configuration section below.

## Configuration
Nextflow configuration is handled by the file `nextflow.config` in the directory
where you're running the nextflow command. The configuration file in this
repository is for running the pipeline on the lewis cluster at Mizzou using
SLURM and mamba, but you can adjust it to use any batch or cloud system you
want. Check out the [nextflow docs](https://www.nextflow.io/docs/edge/index.html)
for more information.

If you don't have a conda environment already set up with racon, minimap2, and
samtools installed in it, you can have nextflow make one for you by changing
the conda line of the config to
```
conda = "racon minimap2 samtools"
```

### Lewis-specific stuff
Nextflow needs a filesystem where locking is allowed for keeping track of which
jobs are running, but not to actually store the data or temporary files you're
creating. On Lewis, HTC allows locking but is slow and HPC does not allow
locking but is fast. To take advantage of the best of both worlds, run this
pipeline from within a project directory in HTC, but set the environment
variable `$NXF_WORK` to point to an empty directory on HPC.

## Running
To download the pipeline and run it on your assembly, just run the command:
```
nextflow run WarrenLab/longread-polish-nf \
    --reference unpolished_assembly.fa \
    --reads long_reads/*.fastq.gz
```
This will align all the reads to your reference and then use the alignments to
correct the assembly.

## TODO
* Write help message
* Convert to DSL2
* Add option for ONT reads
