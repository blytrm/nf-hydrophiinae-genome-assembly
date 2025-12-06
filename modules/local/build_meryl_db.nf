process BUILD_MERYL_DB {
    tag "$sample_id"
    label 'process_medium'
    container 'staphb/meryl:1.4.1'

    input:
    tuple val(sample_id), path(hifi_reads)

    output:
    tuple val(sample_id), path("${sample_id}.meryl")

    script:

    if (params.mock) {
        """
        mkdir ${sample_id}.meryl
        echo "Mock meryl DB created (k=31)" > ${sample_id}.meryl/mock.txt
        """
    } else {
        """
        meryl count k=31 threads=${task.cpus} memory=16 input=${hifi_reads} output ${sample_id}.meryl

        """
    }
}
