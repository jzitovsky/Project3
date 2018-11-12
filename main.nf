#!/usr/bin/env nextflow

params.file_dir = 'data/p2_abstracts/*40.txt'
params.out_dir = 'data/'
params.out_file = 'finalData.csv'

file_channel = Channel.fromPath( params.file_dir )

process simple {
container 'bioconductor/release_core2:R3.5.0_Bioc3.7'

    input:
    file f from file_channel

    output:
    stdout strings

"""
    cat $f
"""
}

process python_transform_list2 {
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


