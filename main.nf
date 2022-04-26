#!/usr/bin/env nextflow

// Re-usable componext for adding a helpful help message in our Nextflow script
def helpMessage() {
    log.info"""
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --vcf_list vcf_files_list.csv
    Mandatory arguments:
      --vcf_list                  [file] A two column comma seperated file with a header.
                                         The files is a list of VCF files split by chromosome to be processed
                                         The 1st column must be a string, the chromosome, eg 1 or chr1 , as found in the VCF chr field
                                         The 2nd column must be a path, pointing to the location of the VCF file
                                         The 3rd column must be a path, pointing to the location of the index of the VCF file

                                         Paths that can be used:
                                         - Local file path, relative to the nextflow execution folder
                                         - Local file path, absolut path
                                         - s3:// links to AWS buckets if awscli is configured
                                         - gs:// links to Google Cloud Platform buckets if gcloud is configured
                                         - ftp:// links from accessible FTP servers
                                         - http:// or https:// links from accessible HTTP servers

                                         A file could look like this:
                                         chr,vcf,index
                                         22,sampleA_chr22.vcf.gz,sampleA_chr22.vcf.gz.csi


    """.stripIndent()
}

// Print specified parameters values
log.info "\nPARAMETERS SUMMARY"
log.info "config            : ${params.config}"
log.info "vcf_list          : ${params.vcf_list}"
log.info "global_container  : ${params.global_container}"
log.info "plink2_container  : ${params.plink2_container}"

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
