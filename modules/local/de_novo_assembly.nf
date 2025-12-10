process DE_NOVO_ASSEMBLY {
    tag "$sample_id - $param_set"
    label 'process_high'
    publishDir "${params.outdir}/de-novo_hifiasm", mode: 'copy'

    input:
    tuple val(sample_id), path(hifi_reads), val(param_set) // param_set e.g., no-post-join.lowQ50

    output:
    tuple val(sample_id), val(param_set), path( "de-novo_${sample_id}.${param_set}.fasta" ), emit: assemblies

    script:
    def args = ""
    if (param_set.contains('no-post-join')) args += ' --no-post-join'
    if (param_set.contains('lowQ50')) args += ' --lowQ 50'

    if (params.mock) {
        """
        touch "de-novo_${sample_id}.${param_set}.fasta"
        echo "de-novo_${sample_id}.${param_set}.fasta"
        """
    } else {
        """
        echo "finalise command"
        # hifiasm ${args} -o "de-novo_${sample_id}.${param_set}" -t ${task.cpus} ${hifi_reads}
        # mv "de-novo_${sample_id}.${param_set}.p_ctg.fasta" "de-novo_${sample_id}.${param_set}.fasta" 
        # specify the p_ctg (haplotype-collapsed) or p_utg (uncollapsed)
        """
    }
}