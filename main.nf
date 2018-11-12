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

process python_transform_list {
    container 'python:3.7-slim'

    input:
    val l from strings.collect()

    output:
    stdout lengths_transformed

    """
    #!/usr/bin/python3.5
    
    numbers = $l
    lstring = 'c(' + ','.join([str(x) for x in numbers]) + ')'
    print(lstring)
    """
}


