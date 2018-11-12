#!/usr/bin/env nextflow

params.file_dir = 'data/fastas/*40.txt'
params.out_dir = 'data/'
params.out_file = 'histogram.png'

file_channel = Channel.fromPath( params.file_dir )

process get_seq_length {
    container 'bioconductor/release_core2:R3.5.0_Bioc3.7'

    input:
    file f from file_channel

    output:
    stdout lengths

    """
    cat(l)
    """
}


lengths_transformed.subscribe {  println it  }
