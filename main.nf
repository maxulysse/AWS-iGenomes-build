#!/usr/bin/env nextflow

/*
kate: syntax groovy; space-indent on; indent-width 2;
================================================================================
=                                 S  A  R  E  K                                =
================================================================================
 New Germline (+ Somatic) Analysis Workflow. Started March 2016.
--------------------------------------------------------------------------------
 @Authors
 Maxime Garcia <maxime.garcia@scilifelab.se> [@MaxUlysse]
 Johannes Alneberg <johannes.alneberg@scilifelab.se> [@alneberg]
 Phil Ewels <phil.ewels@scilifelab.se> [@ewels]
--------------------------------------------------------------------------------
 @Homepage
 https://github.com/MaxUlysse/AWS-iGenomes-build
--------------------------------------------------------------------------------
 @Documentation
 https://github.com/MaxUlysse/AWS-iGenomes-build/README.md
--------------------------------------------------------------------------------
 Processes overview
================================================================================
=                           C O N F I G U R A T I O N                          =
================================================================================
*/

// input
genome_dir = params.genome_dir
gtf_files = params.gtf_files
source = params.source.toLowerCase()

// params
build = params.build

source =
  source == "ensembl" ? "Ensembl" :
  source == "gatk" ? "GATK" :
  source == "ncbi" ? "NCBI" :
  source == "ucsc" ? "UCSC" :
  "Unknown"

/*
================================================================================
=                               P R O C E S S E S                              =
================================================================================
*/

startMessage()

ch_faFiles = Channel.fromPath("${genome_dir}/*")
ch_gtfFiles = Channel.fromPath("${gtf_files}")

// Filter files
// ch_referencesFiles = ch_faFiles.mix(ch_gtfFiles)
ch_referencesFiles = ch_gtfFiles
ch_compressedfiles = Channel.create()
ch_notCompressedfiles = Channel.create()


ch_referencesFiles
  .choice(ch_compressedfiles, ch_notCompressedfiles) {it =~ ".(gz|tar.bz2)" ? 0 : 1}

process DecompressFile {
  tag {f_reference}

  input:
    file(f_reference) from ch_compressedfiles

  output:
    file("*.{vcf,fasta,loci}") into ch_decompressedFiles

  script:
  realReferenceFile="readlink ${f_reference}"
  if (f_reference =~ ".gz")
    """
    gzip -d -c \$(${realReferenceFile}) > ${f_reference.baseName}
    """
  else if (f_reference =~ ".tar.bz2")
    """
    tar xvjf \$(${realReferenceFile})
    """
}

ch_decompressedFiles = ch_decompressedFiles.dump(tag:'DecompressedFile')

ch_fastaFile = Channel.create()
ch_fastaForBWA = Channel.create()
ch_fastaReference = Channel.create()
ch_fastaForSAMTools = Channel.create()
ch_otherFile = Channel.create()
ch_vcfFile = Channel.create()

ch_decompressedFiles
  .choice(ch_fastaFile, ch_vcfFile, ch_otherFile) {
    it =~ ".fasta" ? 0 :
    it =~ ".vcf" ? 1 : 2}

(ch_fastaForBWA, ch_fastaReference, ch_fastaForSAMTools, ch_fastaFileToKeep) = ch_fastaFile.into(4)
(ch_vcfFile, ch_vcfFileToKeep) = ch_vcfFile.into(2)

ch_notCompressedfiles
  .mix(ch_fastaFileToKeep, ch_vcfFileToKeep, ch_otherFile)
  .collectFile(storeDir: params.outDir)

process BuildBWAindexes {
  tag {f_reference}

  publishDir params.outDir, mode: params.publishDirMode

  input:
    file(f_reference) from ch_fastaForBWA

  output:
    file("*.{amb,ann,bwt,pac,sa}") into bwaIndexes

  script:
  """
  bwa index ${f_reference}
  """
}

bwaIndexes.dump(tag:'bwaIndexes')

process BuildReferenceIndex {
  tag {f_reference}

  publishDir params.outDir, mode: params.publishDirMode

  input:
    file(f_reference) from ch_fastaReference

  output:
    file("*.dict") into ch_referenceIndex

  script:
  """
  gatk --java-options "-Xmx${task.memory.toGiga()}g" \
  CreateSequenceDictionary \
  --REFERENCE ${f_reference} \
  --OUTPUT ${f_reference.baseName}.dict
  """
}

ch_referenceIndex.dump(tag:'dict')

process BuildSAMToolsIndex {
  tag {f_reference}

  publishDir params.outDir, mode: params.publishDirMode

  input:
    file(f_reference) from ch_fastaForSAMTools

  output:
    file("*.fai") into ch_samtoolsIndex

  script:
  """
  samtools faidx ${f_reference}
  """
}

ch_samtoolsIndex.dump(tag:'fai')

process BuildVCFIndex {
  tag {f_reference}

  publishDir params.outDir, mode: params.publishDirMode

  input:
    file(f_reference) from ch_vcfFile

  output:
    file("${f_reference}.idx") into ch_vcfIndex

  script:
  """
  igvtools index ${f_reference}
  """
}

ch_vcfIndex.dump(tag:'idx')

// SORT fa files
//
// Make genome.fa
//
// Make bowtie
// Make bowtie2
// Make bwa
// Make Bismark
// Make BED from gtf

/*
================================================================================
=                               F U N C T I O N S                              =
================================================================================
*/

def awsIgenomesBuildMessage() {
  // Display AWS iGenomes build message
  log.info "AWS iGenomes build - Script for building iGenomes ~ ${workflow.manifest.version}"
}

def minimalInformationMessage() {
  // Minimal information message
  log.info "Command Line: " + workflow.commandLine
  log.info "Project Dir : " + workflow.projectDir
  log.info "Launch Dir  : " + workflow.launchDir
  log.info "Work Dir    : " + workflow.workDir
}

def nextflowMessage() {
  // Nextflow message (version + build)
  log.info "N E X T F L O W  ~  version ${workflow.nextflow.version} ${workflow.nextflow.build}"
}

def startMessage() {
  // Display start message
  this.awsIgenomesBuildMessage()
  this.minimalInformationMessage()
}

workflow.onComplete {
  // Display complete message
  this.nextflowMessage()
  this.awsIgenomesBuildMessage()
  this.minimalInformationMessage()
  log.info "Completed at: " + workflow.complete
  log.info "Duration    : " + workflow.duration
  log.info "Success     : " + workflow.success
  log.info "Exit status : " + workflow.exitStatus
  log.info "Error report: " + (workflow.errorReport ?: '-')
}

workflow.onError {
  // Display error message
  this.nextflowMessage()
  this.awsIgenomesBuildMessage()
  log.info "Workflow execution stopped with the following message:"
  log.info "  " + workflow.errorMessage
}
