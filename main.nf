#!/usr/bin/env nextflow
nextflow.enable.dsl = 2
import groovy.yaml.YamlSlurper


// PARAMETERS
params.samplesheet = 'samplesheet.csv'
params.outdir      = 'results'
params.mock        = true
params.hifiasm = 'conf/params_hifiasm.yaml'

// MODULES
// read QC ?
include { BUILD_MERYL_DB } from './modules/local/build_meryl_db.nf'
include { ASSESS_ORIGINAL_GENOME_QC } from './modules/local/assess_original_qc.nf'
include { DE_NOVO_ASSEMBLY } from './modules/local/de_novo_assembly.nf'
// assessment + selection
include { HI_C_SCAFFOLDING } from './modules/local/hi_c_scaffolding.nf'
// assessment + selection

// polish + manual curation + repeat masking > what else?

// final assembly assessment
    // ? repeat annotation
    // ? v2r rough quantification
    // ? gene annotation

// WORKFLOW
workflow {
    // CHANNELS 
    samples_ch = channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true, sep: ',')
        .map { row -> 
            tuple(
                row.sample_id,
                file(row.original_genome),
                file(row.hifi_reads),
                file(row.hic_1),
                file(row.hic_2)
            )
        }
    
    // Meryl (k-mer analysis)
    meryl_ch = BUILD_MERYL_DB(samples_ch.map { tuple(it[0], it[2]) }) // sample_id & hifi_reads
    qc_input_ch = samples_ch.join(meryl_ch) // [id, genome, hifi, hic1, hic2, meryl]

    // Original Genome QC
    assess_original_qc_ch = ASSESS_ORIGINAL_GENOME_QC(qc_input_ch.map { tuple(it[0], it[1], it[5]) }) //  sample_id, genome, meryl

    // Hifiasm: De Novo Assemblies
    def yaml = new YamlSlurper().parse(file(params.hifiasm))    
    hifiasm_params_ch = channel.fromList(yaml.parameters.collect { it.set })
    de_novo_input_ch = samples_ch.map { tuple(it[0], it[2]) } // sample_id & hifi_reads
        .combine(hifiasm_params_ch) // id , hifi reads , params for each
    de_novo_ch = DE_NOVO_ASSEMBLY(de_novo_input_ch) 

    // Hi-C Scaffolding
    // add yaml
    // hi-c_params_ch
    hi_c_scaffolding_input_ch = de_novo_ch
        .join(samples_ch.map { tuple(it[0], it[3], it[4]) }) // sample_id. hi-c_1, hi-c_2
    hi_c_scaffolding_ch = HI_C_SCAFFOLDING(hi_c_scaffolding_input_ch)

}

/* 
======= NOTES + TO DO LIST: =======

    explore and list more hifiasm parameters

    count parameters/inputs


*/
