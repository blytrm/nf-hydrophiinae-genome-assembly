#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// PARAMETERS
params.samplesheet = 'samplesheet.csv'
params.outdir      = 'results'
params.mock        = true

// CHANNELS
Channel
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
    .set { samples_ch }


// PROCESS: Assess Original Genome QC 
process ASSESS_ORIGINAL_GENOME_QC {
    tag "$sample_id"
    publishDir "${params.outdir}/01_original_qc/${sample_id}", mode: 'copy', overwrite: true

    input:
    tuple val(sample_id), path(original_genome), path(hifi_reads), path(hic_1), path(hic_2)

    output:
    path "quast_report.txt"
    path "busco_summary.txt"
    path "merqury_qv.txt"

    script:
    if (params.mock) {
        """
        echo "=== MOCK MODE: Assessing quality of ${original_genome} (sample: ${sample_id}) ==="

        echo "QUAST - N50: 28.0 Mb | Contigs: 1,896" > quast_report.txt
        echo "BUSCO - Complete: 99.22% (D:0.47%) | Fragmented: 0.31% | Missing: 0.47%" > busco_summary.txt
        echo "Merqury - QV: 45.2 | Completeness: 98.97% | k-mer completeness: 98.8%" > merqury_qv.txt
        """
    } else {
        """
        quast.py --large --fast -o quast ${original_genome}
        busco -i ${original_genome} -l squamata_odb10 -m genome -o busco --offline
        # merqury will be added in part 2
        """
    }
}




// WORKFLOW
workflow {
    samples_ch | ASSESS_ORIGINAL_GENOME_QC
}