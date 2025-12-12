process DE_NOVO_ASSEMBLY {
    tag "$sample_id - $param_set"
    label 'process_high'
    publishDir "${params.outdir}/de-novo_hifiasm/${sample_id}/${param_set}", mode: 'copy'

    // conda
    // container

    input:
    tuple val(sample_id), path(hifi_reads), val(param_set), val(args)

    output:
    tuple val(sample_id), val(param_set), path( "de-novo_${sample_id}.${param_set}.fasta" ), emit: assemblies

    script:

    if (params.mock) {
        """
        touch de-novo_${sample_id}.${param_set}.fasta
        echo "de-novo_${sample_id}.${param_set}.fasta"
        """
    } else {
        """
        # Hifiasm command:
        hifiasm \
        ${args} \
        -o de-novo_${sample_id}.${param_set} \
        -t ${task.cpus} \
        ${hifi_reads} \
        wait
        # GFA to fa ?
        # p_utg or p_ctg ?
        # mv "de-novo_${sample_id}.${param_set}.p_ctg.fasta" "de-novo_${sample_id}.${param_set}.fasta" 
        """
    }
}