process BASESPACE {
    tag "$run"
    container 'quay.io/csgenetics/basespace-cli:0.1'

    input:
    val run
    path config

    output:
    path "${run}/*fastq.gz", emit: fastqs
    path "${run}/*json"    , emit: jsons

    script:
    """
    cp /bin/bs .

    RUNID=\$(./bs list run | grep $run | awk '{print \$4}')
    mkdir -p $run

    #this creates the list of all the lanes for downloading
    ./bs list dataset --input-run \$RUNID | awk '{print \$2;}' > ${run}.prefix.txt
    sed -i '1,3d' ${run}.prefix.txt


    for PREFIX in \$(cat ${run}.prefix.txt); do
        ID=\$(./bs list dataset --input-run \$RUNID | grep \$PREFIX | awk '{print \$4;}')
        echo \$PREFIX \$ID ">>" $run
        ./bs download dataset ---input-run \$RUNID -i \$ID -o $run

    done
    wait
    """
}

process FASTQC {
    tag ""
    container 'quay.io/biocontainers/fastqc:0.11.9--0'

    input:
    path reads 

    output:
    path "*.html", emit: html
    path "*.zip" , emit: zip

    script:
    """
    fastqc --threads $task.cpus *fastq.gz
    """
}

process POOL_LANES {
    tag "${ogid}"
    container 'quay.io/biocontainers/bbmap:39.19--he5f24ec_0'
    
    input:
    tuple val(ogid), path(reads)

    output:
    tuple val(ogid), path("${ogid}.rna.${params.date}.R1.fq.gz"), path("${ogid}.rna.${params.date}.R2.fq.gz"), emit: pooled_reads
    path("${ogid}.rna.${params.date}.paircheck.log")

    script:
    """
    cat ${ogid}*R1*.fastq.gz > ${ogid}.cat.rna.${params.date}.R1.fq.gz
    cat ${ogid}*R2*.fastq.gz > ${ogid}.cat.rna.${params.date}.R2.fq.gz
    wait 
    repair.sh -Xmx180g in=${ogid}.cat.rna.${params.date}.R1.fq.gz in2=${ogid}.cat.rna.${params.date}.R2.fq.gz out=${ogid}.rna.${params.date}.R1.fq.gz out2=${ogid}.rna.${params.date}.R2.fq.gz 2>&1 | grep ':' | tee -a "${ogid}.rna.${params.date}.paircheck.log"
    """
}

process FASTP {
    tag "${ogid}"
    container 'quay.io/biocontainers/fastp:0.24.1--heae3180_0'

    input:
    tuple val(ogid), path(r1), path(r2)

    output:
    tuple val(ogid), path("${ogid}.rna.${params.date}.R2.fastq.gz"), path("${ogid}.rna.${params.date}.R1.fastq.gz"), emit: trimmed_reads
    path("*.fastp.json"), emit: fastp_json
    path("*.fastp.html"), emit: fastp_html

    script:
    """
    fastp \\
        -i ${r1} \\
        -I ${r2} \\
        -o "${ogid}.rna.${params.date}.R1.fastq.gz" \\
        -O "${ogid}.rna.${params.date}.R2.fastq.gz" \\
        --trim_poly_x \\
        --length_required 50 \\
        --json '${ogid}.rna.${params.date}.fastp.json' \\
        --html '${ogid}.rna.${params.date}.fastp.html' \\
        --report_title="${ogid}.rna.${params.date}fastp" \\
        --thread $task.cpus \\
        2>&1 | tee ${ogid}.rna.${params.date}.fastp.log
    """


}

process MULTIQC {
    tag ""
    container 'quay.io/biocontainers/multiqc:1.20--pyhdfd78af_1'

    input:
    path  multiqc_files, stageAs: "?/*"

    output:
    path "*multiqc_report.html", emit: report
    path "*_data"              , emit: data
    path "*_plots"             , optional:true, emit: plots

    script:
    """
    multiqc \\
        --force \\
        .
    """
}

workflow {

    // Download from BaseSpace
    BASESPACE(params.run, params.bs_config)

    // Group reads by OGID
    reads_by_ogid = BASESPACE.out.fastqs
        .flatten()
       .map { file -> 
            def ogid = file.name.split('_')[0]
            return tuple(ogid, file)
        }
        .groupTuple()

    // Run FastQC on all fastq files
    FASTQC(BASESPACE.out.fastqs.flatten())

    // Pool lanes for each OGID
    POOL_LANES(reads_by_ogid)

POOL_LANES.out.pooled_reads.view()

    FASTP(POOL_LANES.out.pooled_reads)

    // Run MultiQC on FastQC and fastp outputs
    MULTIQC(
        FASTQC.out.zip.collect().mix(
            FASTP.out.fastp_json.collect(),
            FASTP.out.fastp_html.collect()
        ).collect()
    )
}

