process HI_C_SCAFFOLDING {
    tag "$sample_id - $param_set"
    label 'process_high'
    publishDir "${params.outdir}/hi-c_scaffolding", mode: 'copy'

    input:
    tuple val(sample_id), val(param_set), path("de-novo_${sample_id}.${param_set}.fasta"), path(hic_1), path(hic_2)

    output:
    tuple val(sample_id), val(param_set), path("hi_c_scaffold_${sample_id}.${param_set}.fasta"), path("hi_c_scaffold_${sample_id}.${param_set}.agp"), emit: scaffolds

    script:
    if (params.mock) {
        """
        touch "hi_c_scaffold_${sample_id}.${param_set}.fasta"
        touch "hi_c_scaffold_${sample_id}.${param_set}.agp"
        echo "hi_c_scaffold_${sample_id}.${param_set}.fasta"
        echo "hi_c_scaffold_${sample_id}.${param_set}.agp"
        echo "hi_c_scaffold_${sample_id}.${param_set}.filtered.bam"
        """
    } else {
        """
        # Hi-C Alignment to the Assembly
        bwa index "de-novo_${sample_id}.${param_set}.fasta"
        bwa mem -5SP -t ${task.cpus} "de-novo_${sample_id}.${param_set}.fasta" ${hic_1} ${hic_2} | \
            samblaster | \
            samtools view - -@ 14 -S -h -b -F 3340 -o "hi_c_scaffold_${sample_id}.${param_set}.bam"

        # Filter alignments with MAPQ >= 1 and edit distance < 3
        /HapHiC/utils/filter_bam "hi_c_scaffold_${sample_id}.${param_set}.bam" 1 --nm 3 --threads ${task.cpus} | \
            samtools view - -b -@ 14 -o "hi_c_scaffold_${sample_id}.${param_set}.filtered.bam"

        # HapHiC Scaffolding
        /HapHiC/haphic pipeline "de-novo_${sample_id}.${param_set}.fasta" \
            "hi_c_scaffold_${sample_id}.${param_set}.filtered.bam" \
            --threads ${task.cpus} \
            --processes ${task.cpus} \
            --output "hi_c_scaffold_${sample_id}.${param_set}.fasta" \
            --output-agp "hi_c_scaffold_${sample_id}.${param_set}.agp"
        """
    }
}