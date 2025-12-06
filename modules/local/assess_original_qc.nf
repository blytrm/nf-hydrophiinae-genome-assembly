// PROCESS: Assess Original Genome QC 
process ASSESS_ORIGINAL_GENOME_QC {
    tag "$sample_id"
    publishDir "${params.outdir}/01_original_qc/${sample_id}", mode: 'copy', overwrite: true

    // add container ?
    // container '___' 

    input:
    tuple val(sample_id), path(original_genome), path(meryl_db)

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
        # add commands + parameters
        # quast.py --large --fast -o quast ${original_genome}
        # compleasm -i ${original_genome} -l squamata_odb10 -m genome -o busco --offline
        # merqury will be added in part 2
        """
    }
}