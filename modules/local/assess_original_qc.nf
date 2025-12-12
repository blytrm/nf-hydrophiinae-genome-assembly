// PROCESS: Assess Original Genome QC 
process ASSESS_ORIGINAL_GENOME_QC {
    tag "$sample_id"
    publishDir "${params.outdir}/01_original_qc/", mode: 'copy', overwrite: true

    // add container ?
    // container '___' 

    input:
    tuple val(sample_id), path(original_genome), path(meryl_db)

    output:
    path "QUAST/quast_report.txt"
    path "BUSCO/busco_summary.txt"
    path "MERQURY/merqury_qv.txt"
    path "output_statistics/${sample_id}_original_qc_summary.tsv"

    script:
    if (params.mock) {
        // tuple val(sample_id), N50, Contigs #, BUSCO %, BUSCO d%, BUSCO f%, Merqury QV, Merqury completeness, Merqury k-mer completeness
        """
        echo "=== MOCK MODE: Assessing quality of ${original_genome} (sample: ${sample_id}) ==="

        mkdir -p QUAST BUSCO MERQURY output_statistics
        echo "QUAST - N50: 28.0 Mb | Contigs: 1,896" > QUAST/quast_report.txt
        echo "BUSCO - Complete: 99.22% (D:0.47%) | Fragmented: 0.31% | Missing: 0.47%" > BUSCO/busco_summary.txt
        echo "Merqury - QV: 45.2 | Completeness: 98.97% | k-mer completeness: 98.8%" > MERQURY/merqury_qv.txt
        echo "${sample_id}  28.0    1896    99.22    0.47    0.31    45.2    98.97    98.8" > output_statistics/${sample_id}_original_qc_summary.tsv
        """
    } else {
        """
        mkdir -p QUAST BUSCO MERQURY
        # add commands + parameters
        # quast.py --large --fast -o QUAST ${original_genome}
        # compleasm -i ${original_genome} -l squamata_odb10 -m genome -o BUSCO --offline
        # merqury will be added in part 2
        """
    }
}