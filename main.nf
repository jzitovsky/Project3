#!/usr/bin/env nextflow

params.file_dir = 'data/p2_abstracts/*40.txt'
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
    cat $f
    """
}

process python_transform_list {
    container 'python:3.7-slim'

    input:
    val l from lengths.collect()

    output:
    stdout lengths_transformed

    """
    #!/usr/local/bin/python
    numbers = $l
    lstring = 'c(' + ','.join([str(x) for x in numbers]) + ')'
    print(lstring)
    """
}

lengths_transformed.subscribe {  println it  }
