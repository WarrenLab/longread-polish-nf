#!/usr/bin/env nextflow

params.reference = 'unpolished.fa'
params.reads = 'long_reads/*.fastq.gz'
params.numChunks = 100

reference = file(params.reference)
Channel.fromPath(params.reads)
    .map { f -> tuple(f.baseName, f) }
    .set { readsToAlign }
Channel.fromPath(params.reads)
    .set { readsToCat }

process faidx {
    input:
    file 'ref.fa' from reference

    output:
    file 'ref.fa.fai' into referenceFaidx

    """
    samtools faidx ref.fa
    """
}

process align {
    cpus 16
    memory '128 GB'

    input:
    file 'ref.fa' from reference
    set id, file(inputReadFastq) from readsToAlign

    output:
    file "${id}.bam" into aligned

    """
    minimap2 -a -x map-pb -t ${task.cpus} ref.fa ${inputReadFastq} | \
        samtools view -bh - | samtools sort - > ${id}.bam
    """
}

process mergeBams {
    publishDir 'aligned'

    input:
    file '*.bam' from aligned.collect()

    output:
    file 'all.bam' into alignedAll
    file 'all.bam.bai' into alignedAllBai

    """
    samtools merge all.bam *.bam
    samtools index all.bam
    """
}

referenceFaidx.into { referenceFaidx1; referenceFaidx2 }
referenceFaidx1
    .splitCsv(sep: "\t")
    .map { it[0] }
    .combine(referenceFaidx2)
    .combine(alignedAll)
    .combine(alignedAllBai)
    .set { contigsRefBam }

process racon {
    cpus 16
    memory '64 GB'

    input:
    set val(ctg),
        file('ref.fa.fai'),
        file('all.bam'),
        file('all.bam.bai') from contigsRefBam
    file 'ref.fa' from reference

    output:
    file("${ctg}_corrected.fa") into corrected

    """
    samtools faidx ref.fa $ctg > contig.fa
    samtools view -bh all.bam $ctg > contig.bam
    samtools view -h contig.bam > contig.sam
    samtools fastq contig.bam > contig.fastq

    # only run racon if there are reads to run it on; otherwise it will crash
    if [ -s contig.fastq ]; then
        racon -t ${task.cpus} contig.fastq contig.sam contig.fa \
            > ${ctg}_corrected.fa
    else
        cp contig.fa ${ctg}_corrected.fa
    fi
    """
}

process catContigs {
    publishDir 'out'

    input:
    file "*_corrected.fa" from corrected.collect()

    output:
    file "corrected.fa" into correctedCatted

    """
    cat *_corrected.fa > corrected.fa
    """
}


