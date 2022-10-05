# Minimal Nextflow pipeline that converts VCF files to PLINK binary fileset

The pipeline takes as input a 3 column comma separated file, with chromosome, path to vcf and path to index of vcf and converts each 
VCF to a PLINK binary fileset.

## Quick start:

Before starting clone the current repository using the command line:

```
git clone https://github.com/lifebit-ai/plink-nextflow-example
cd plink-nextflow-example
```

Example command:

```
  nextflow run main.nf --vcf_list testdata/local_files_vcf_list_chr_21_22.csv 
```


# Nextflow documentation

![nextflow_logo](https://raw.githubusercontent.com/PhilPalmer/lbf-hack-tutorial/master/images/nextflow.png)


**Main outcome:** *During the first session you will build a minimal pipeline to learn the basics of Nextflow including:*
- [Parameters](https://www.nextflow.io/docs/latest/getstarted.html?highlight=parameters#pipeline-parameters)
- [Processes](https://www.nextflow.io/docs/latest/process.html) (inputs, outputs & scripts)
- [Channels](https://www.nextflow.io/docs/latest/channel.html)
- [Operators](https://www.nextflow.io/docs/latest/operator.html)
- [Configuration](https://www.nextflow.io/docs/latest/config.html)

## 1. Installing Nextflow

We have [Conda](https://docs.conda.io/en/latest/) installed so we can run the following to install Nextflow:

```bash
conda init bash
exec -l bash
```

Then create a new conda environment:

```bash
conda create -n nf
conda activate nf
```

And install Nextflow there with:

```bash
conda install -c bioconda nextflow=20.01.0
```

Activate the Nextflow conda environment:
```
conda activate nf
```


You can then test your installation of Nextflow with:
```
nextflow run hello
```


## 2. Nextflow Parameters

Now that we have Nextflow & Docker installed we're ready to run our first script:

1. Create a file `main.nf` & open this in your code/text editor
2. In this file write the following:

```nextflow
// main.nf
params.vcf_list = false

println "My vcf_list: ${params.vcf_list}"
```

The first line initialises a new variable (`params.vcf_list`) & sets it to `false`
The second line prints the value of this variable on execution of the pipeline.

We can now run this script & set the value of `params.vcf_list` to one of our example CSV files in the testdata folder with the following command:
```
nextflow run main.nf --vcf_list testdata/vcf_list_chr_21_22.csv
```

This should return the value you passed on the command line

#### Recap
Here we learnt how to define parameters & asssign them values via command line arguments in Nextflow


## 3. Nextflow Processes (inputs, outputs & scripts)

Nextflow allows the execution of any command or user script by using a `process` definition.

A process is defined by providing three main sections:
1. the command [script](https://www.nextflow.io/docs/latest/process.html#script).
2. the process [inputs](https://www.nextflow.io/docs/latest/process.html#inputs),
3. the process [outputs](https://www.nextflow.io/docs/latest/process.html#outputs)

In our main script we want to add the following:

- script
- input
- output

### The `script` section

To convert a bash command to the the Nextflow process script we will follow 3 steps:

1. **Bash:** Formulate bash command with hardocded paths and values
2. **Bash:** Replace hardcoded paths and values with bash variables
3. **Nextflow:** Replace bash variables with Nextflow variables


| Language | Command|
| -------------- | ----------- |
| Bash (hardcoded)  | `plink2 --vcf testdata/sampleA_chr22.vcf.gz --make-bed --out chrom_22`    |
| Bash (parameterised)  | `VCF_FILE="testdata/sampleA_chr22.vcf.gz"`<br>`CHR=22`<br>`plink2 --vcf ${VCF_FILE} --make-bed --out chrom_${CHR}`   |
| Nextflow (parameterised)  |  `process convert_vcf_to_plink {` <br><br>  `input:`<br>`set val(chr), file(vcf_file), file(index_file) from ch_vcf_files`<br><br>  `script:`<br>  `"""`<br>  `plink2 --vcf ${vcf_file} --make-bed --out chrom_${chr}`<br>  `"""`<br>`}`  |


> NOTE: After constructing the script we will define the Nextflow variables in the `input` and `output` directives.

#### Step 1: Formulate bash command with hardocded paths and values

Let's review the `plink2` command for converting a VCF file to a PLINK binary fileset using bash:

```bash
plink2 --vcf testdata/sampleA_chr22.vcf.gz --make-bed --out chrom_22
```

> **NOTE**: If Docker is available this command can be used to not have to install dependencies: `docker run --rm -v $PWD:$PWD -w $PWD -it quay.io/lifebitai/plink2`. To exit the container after executing the command type `exit`.

<details>
<summary>Expected output:</summary>

```
PLINK v2.00a2.3LM 64-bit Intel (24 Jan 2020)   www.cog-genomics.org/plink/2.0/
(C) 2005-2020 Shaun Purcell, Christopher Chang   GNU General Public License v3
Logging to chrom_22.log.
Options in effect:
  --make-bed
  --out chrom_22
  --vcf testdata/sampleA_chr22.vcf.gz

Start time: Tue Apr 26 07:44:38 2022
7960 MiB RAM detected; reserving 3980 MiB for main workspace.
Using up to 5 compute threads.
--vcf: 68 variants scanned.
--vcf: chrom_22-temporary.pgen + chrom_22-temporary.pvar +
chrom_22-temporary.psam written.
2000 samples (0 females, 0 males, 2000 ambiguous; 2000 founders) loaded from
chrom_22-temporary.psam.
68 variants loaded from chrom_22-temporary.pvar.
Note: No phenotype data present.
Writing chrom_22.fam ... done.
Writing chrom_22.bim ... done.
Writing chrom_22.bed ... done.
End time: Tue Apr 26 07:44:38 2022
```

</details>
<br>

#### Step 2: Formulate bash command with parameterised paths and values as variables

Let's parameterise the hard coded paths using bash variable:

```bash
VCF_FILE="testdata/sampleA_chr22.vcf.gz"
CHR=22
plink2 --vcf ${VCF_FILE} --make-bed --out chrom_${CHR}
```

#### Step 3: Formulate bash command with hardocded paths

> **NOTE**: Nextflow is implememnted in Groovy, the comment character for Groovy is a double forward slash `//`. We will use comments to annotate the Nextflow sections below.


```groovy
// contents of main.nf

// TODO: add the channel that defines the variables of the input directive

process convert_vcf_to_plink {

  // Input directive
  input:
  set val(chr), file(vcf_file), file(index_file) from ch_vcf_files

  // Output directive
  script:
  """
  plink2 --vcf ${vcf_file} --make-bed --out chrom_${chr}
  """
}
```

Here we **invented** the variables `chr`, `vcf_file`, `index_file`, we will see in the **Channel** section where this variables are defined via input data and a specific to Nextflow concept named _channels_.

#### Recap

In this section we started from a bash command for converting VCF files to plink and formatted it as a Nextflow `script`, one of the main required sections in a Nextflow pipeline. In the next section we will see how to create the sections `input` and `output`.

### The `input` and `output` sections: Nextflow Channels

`Channels` is a specific concept that describes Nextflow objects that hold the inputs and outputs of Nextflow processes.
They are used as vessels to carry files and value.

<!--
There are two types of channels:
1. [Queue channels](https://www.nextflow.io/docs/latest/channel.html#queue-channel) can be used to connect two processes or operators. They are usually produced from factory methods such as [`from`](https://www.nextflow.io/docs/latest/channel.html#from)/[`fromPath`](https://www.nextflow.io/docs/latest/channel.html#frompath) or by chaining it with methods such as [`map`](https://www.nextflow.io/docs/latest/operator.html#operator-map). **Queue channels are consumed upon being read.**
2. [Value channels](https://www.nextflow.io/docs/latest/channel.html#value-channel) a.k.a. singleton channel are bound to a single value and can be read unlimited times without consuming there content. Value channels are produced by the value factory method or by operators returning a single value, such us first, last, collect, count, min, max, reduce, sum.
-->


#### The `input` section

How to provide input files to a Nextflow process

**Important notes:**

- All files should be transferred from one process to the other via `Channels`

In our `main.nf` we can add the following snippet, that provides a template channel which allows us to prepare for Nextflow many files from a csv file.

```groovy
// Re-usable component to create a channel with the links of the files by reading the design file
Channel
    .fromPath(params.vcf_list)
    .ifEmpty { error "No file with list of vcf files found at the location ${params.vcf_list}" }
    .splitCsv(sep: ',', skip: 1)
    .map { chr,vcf,index -> [ chr, file(vcf), file(index) ] }
    .set { ch_vcf_files }
```

This file by convention is called **design file** and provides the path to all the files we wish to process in parallel with our Nextflow pipeline.
Typical examples can be genomic files split per genomic region or per chromosome.

The design file that we will use for this example can be found in [testdata/vcf_list_chr_21_22.csv](./testdata/vcf_list_chr_21_22.csv).
The file [testdata/vcf_list_chr_21_22.csv](./testdata/vcf_list_chr_21_22.csv) is a 3 column comma seperated file with a header,
and is a list of VCF files split by chromosome to be processed in parallel.

1. The 1st column must be a string, the chromosome, eg `1` or `chr1` , as found in the VCF chr field
2. The 2nd column must be a path, pointing to the location of the VCF file
3. The 3rd column must be a path, pointing to the location of the index of the VCF file

Example nput file preview with local paths:

```
chr,vcf,index
21,vcfs/sampleA_chr21.vcf.gz,vcfs/sampleA_chr21.vcf.gz.csi
22,vcfs/sampleA_chr22.vcf.gz,vcfs/sampleA_chr22.vcf.gz.csi
```

Paths that can be used:
- Local file path, relative to the nextflow execution folder
- Local file path, absolut path
- s3:// links to AWS buckets if awscli is configured
- gs:// links to Google Cloud Platform buckets if gcloud is configured
- ftp:// links from accessible FTP servers
- http:// or https:// links from accessible HTTP servers

> **NOTE**: In our example we will use s3 paths from a publicly accessible AWS bucket.


```groovy
//main.nf

// Re-usable component to create a channel with the links of the files by reading the design file
Channel
    .fromPath(params.vcf_list)
    .ifEmpty { error "No file with list of vcf files found at the location ${params.vcf_list}" }
    .splitCsv(sep: ',', skip: 1)
    .map { chr,vcf,index -> [ chr, file(vcf), file(index) ] }
    .set { ch_vcf_files }

// Re-usable process skeleton that performs a simple operation, listing files
process convert_vcf_to_plink {
  tag "chrom: ${chr}, vcf: ${vcf_file} "
  publishDir "results", mode: 'copy'

  input:
  set val(chr), file(vcf_file), file(index_file) from ch_vcf_files

  output:
  file "*.{bed,bim,fam}" into ch_results

  script:
  """
  plink2 --vcf ${vcf_file} --make-bed --out chrom_${chr}
  """
}

```

To run the pipeline:
```bash
nextflow run main.nf --fastq_list vcf_list_chr_21_22.csv
```

### 5. Nextflow Configuration

Configuration, such as parameters, containers & resources eg memory can be set in `config` files such as [`nextflow.config`](https://www.nextflow.io/docs/latest/config.html#configuration-file).

For example our `nextflow.config` file might look like this:

```groovy
// All default parameters that can be defined from the command like
// Example: nextflow run --vcf_list vcf_sample_list.csv --plink2_container 'quay.io/lifebitai/plink2' --echo true ..
params {
  vcf_list = false
  config = 'conf/standard.config'
  global_container = 'quay.io/lifebitai/ubuntu:18.10'
  plink2_container = 'quay.io/lifebitai/plink2'
  echo = false
}

// Process configuration for resources eg cpus, memory, container image to be used
process {

  // Global configurations that are used as default for all processes unless overwritten
  cpus = 2
  memory = "2.GB"
  container = params.global_container
  echo = params.echo

  // Specific configuration for a process named.
  // The definitions here overwrite the global process definitions for this specific process
  withName: convert_vcf_to_plink {
    container = params.plink2_container
  }
}

// Profiles are Aliases used to refer to a configuration file and inherit all the parameters defined in the config file they point to
profiles {
   standard { includeConfig params.config }
   test { includeConfig 'conf/test.config' }
}
```

The pipeline can now be run with the following:
```bash
nextflow run main.nf -profile test
```
### 6. Equivalent execution commands using configs, profiles and parameters

For this Nextflow pipeline, dependencies are provided via container images. If executing in an environment with Docker container engine available, add the flag `-with-docker`, if using Singularity add the respective flag `-with-singularity`.

NOTE: For this example, we are assuming Docker is available, hence the `-with-docker` will be appending in the Nextflow execution commands.

Below 3 examples are used to highlight the different ways parameters can be defined for a Nextflow pipeline with the use of 

1. Parameters passed via the command line
2. Configs
3. Profiles
#### Using parameters

Explicit configuration by passing parameters from the command line:

```
nextflow run main.nf --vcf_list testdata 'testdata/vcf_list_chr_21_22.csv
```

#### Configuration file (referred to as `config`)
To execute the Nextflow pipeline with example parameters using a bundle of parameters defined in a configuration file:

```
nextflow run main.nf --config conf/test.config' -with-docker
```

#### Alias to configuration file (referred to as `profile`)

This configuration is equivalent to the convenience profile named `test`:

```
nextflow run main.nf -profile test -with-docker
```

#### Mix & match

Configuration files, profiles and explicit parameter definition from the command line can be combined.
The order matters, as if one parameter is defined in multiple places, the last parameter mention will be evaluated:

```
nextflow run main.nf --global_container 'quay.io/lifebitai/hail:1.0.0' -profile test -with-docker
```
