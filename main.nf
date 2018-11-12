#!/usr/bin/env nextflow

params.file_dir = 'data/p2_abstracts/*40.txt'
params.out_dir = 'data/'
params.out_file = 'finalData.csv'

file_channel = Channel.fromPath( params.file_dir )

process simple {

    input:
    file f from file_channel

    output:
    stdout strings

"""
    cat $f
"""
}

strings.subscribe {  println it  }

