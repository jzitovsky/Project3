#!/usr/bin/env nextflow

params.file_dir = 'data/p2_abstracts/*40.txt'
params.out_dir = 'data/'
params.out_file = 'histogram.png'

file_channel = Channel.fromPath( params.file_dir )

process get_abstracts {

    input:
    file f from file_channel

    output:
    stdout strings

    """
    cat $f
    """
}

process process_abstracts {

    input:
    val s from strings

    output:
    file '*.rds' into rds_out

    """
    Rscript $baseDir/bin/processData.R "$s"
    """
}



rds_out.subscribe {  println it  }
