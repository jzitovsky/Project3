params.file_dir = 'data/p2_abstracts/*.txt'
params.out_dir = './'

file_channel = Channel.fromPath( params.file_dir )

//This process extracts the collaborators and the description words from each abstract, and saves them in .txt files with values separated by tabs
process process_abstracts {

    	input:
    	file f from file_channel

    	output:
   	file '*.collaborators.txt' into col_out
	file '*.words.txt' into words_out
	

   	"""
    	Rscript $baseDir/bin/processData.R $f
    	"""
}

//This process combines the text files created previously into two giant text files (one for collaborators and one for words), where new lines separate values (i.e. collaborators/words) for different abstracts, and tabs separate values (i.e. collaborators/words) within each abstract. The Rscript then reads in these giant text files and spits out csvs containing  collaborator and word frequency counts  across abstracts
process analyze_data {
	publishDir params.out_dir, mode: 'copy'

	input: 
	file c from col_out.collectFile(name: 'collaborators.txt', newLine: true)
	file w from words_out.collectFile(name: 'words.txt', newLine: true)

	output:
	file '*.csv' into results
 
	"""
	Rscript $baseDir/bin/analyzeData.R $c $w
	"""
}
