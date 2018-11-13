params.file_dir = 'data/p2_abstracts/*.txt'
params.out_dir = 'data/'
params.out_file = 'histogram.png'

file_channel = Channel.fromPath( params.file_dir )

process process_abstracts {

    input:
    file f from file_channel

    output:
    file '*.rds' into rds_out

    """
    Rscript $baseDir/bin/processData.R $f
    """
}

rds_out.subscribe {  println it  }
