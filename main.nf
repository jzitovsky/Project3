params.file_dir = 'data/p2_abstracts/*.txt'
params.out_dir = 'data/'
params.out_file = 'histogram.png'

file_channel = Channel.fromPath( params.file_dir )

process process_abstracts {

    	input:
    	file f from file_channel

    	output:
   	file '*.collaborators.txt' into col_out
	file '*.words.txt' into words_out
	file '*.unique.txt' into unq_out
	

   	"""
    	Rscript $baseDir/bin/processData.R $f
    	"""
}

process analyze_data {

	input: 
	file c from col_out.collectFile(name: 'collaborators.txt', newLine: true)
	file w from words_out.collectFile(name: 'words.txt', newLine: true)
	file u from unq_out.collectFile(name: 'unqWords.txt', newLine: true)

	output:
	file '*.rds' into analout
 
	"""
	Rscript $baseDir/bin/analyzeData.R $c $w $u
	"""
}

analout.subscribe{ println it }

