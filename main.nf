#!/usr/bin/env nextflow

params.file_dir = 'data/p2_abstracts/*4.txt'
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

process python_transform_list {
    container 'python:3.7-slim'

    input:
    val l from strings.collect()

    output:
    stdout lengths_transformed

    """
    #!/usr/local/bin/python

    numbers = $l
    lstring = 'c(' + ','.join([str(x) for x in numbers]) + ')'
    print(lstring)
    """
}

process simple2 {
    container 'rocker/tidyverse:3.5'
    publishDir params.out_dir, mode: 'copy'

    input:
    val l from lengths_transformed

    output:
    file params.out_file into last_file

    """
    #!/usr/local/bin/Rscript

    string = $l
data.frame(string)

    write.csv(string, '$params.out_file')
    """
}

lengths_transformed.subscribe {  println it  }
