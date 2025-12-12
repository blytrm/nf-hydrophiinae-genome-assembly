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
include { HI_C_SCAFFOLDING } from './modules/local/hi_c_scaffolding.nf'
// assessment + selection

// polish + manual curation + repeat masking > what else?

// final assembly assessment
    // ? repeat annotation
    // ? v2r rough quantification
    // ? gene annotation

// Function to generate parameter combinations
def hifiasmParamComb(yaml) {
    def paramGroups = yaml.parameters
    def combinations = []
    // Get all parameter categories
    def categories = paramGroups.keySet() as List
    def generateComb
    generateComb = { index, current ->
        if (index >= categories.size()) {
            def paramSet = current.collect { it.name }.join('_')
            def args = current.collect { it.flag }.findAll { it != "" }.join(' ')
            combinations << [set: paramSet, args: args]
            return
        }
        def category = categories[index]
        paramGroups[category].each { option ->
            generateComb(index + 1, current + [option])
        }
    }
    generateComb(0, [])
    return combinations
}



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
    // Parse YAML + generate parameter combinations
    def yaml = new YamlSlurper().parse(file(params.hifiasm))
    def allComb = hifiasmParamComb(yaml)
    // Channel wih Parameters + arguements
    hifiasm_params_ch = channel.fromList(allComb.collect { [it.set, it.args] })
    // Combine samples + parameter combinations
    de_novo_input_ch = samples_ch.map { tuple(it[0], it[2]) } // sample_id & hifi_reads
        .combine(hifiasm_params_ch)
        .map { sample_id, hifi_reads, param_set, args -> tuple(sample_id, hifi_reads, param_set, args) }
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
