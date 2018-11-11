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

process r_transform_list {

    input:
    val l from strings.collect()

    output:
    stdout lengths_transformed

    """
    #!/usr/bin/Rscript

    print($l)
    """

