params.file_dir = 'data/p2_abstracts/*.txt'
params.out_dir = 'data/'
params.out_file = 'histogram.png'

file_channel = Channel.fromPath( params.file_dir )

process process_abstracts {

    	input:
    	file f from file_channel

    	output:
   	file '*.collaborators.csv' into col_out
	file '*.words.csv' into words_out
	file '*.unique.csv' into unq_out
	

   	"""
    	Rscript $baseDir/bin/processData.R $f
    	"""
}

process analyze_data {

	input: 
	file c from col_out.collectFile(name: 'collaborators.csv', newLine: true)
	file w from words_out.collectFile(name: 'words.csv', newLine: true)
	file u from unq_out.collectFile(name: 'unqWords.csv', newLine: true)

	output:
	file 'saveThisShit.rds' into out_analysis 

	"""
	Rscript $baseDir/bin/analyzeThisShit.R $c $w $u
	"""
}

out_analysis.subscribe{ println it }

