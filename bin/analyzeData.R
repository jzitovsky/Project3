library(tidyverse)
library(magrittr)
library(strex)

#reading in two text files, one of words and one of collaborators, where each new line represents another abstract, and tabs separate words/collaborators within abstracts
args = commandArgs(trailingOnly = TRUE)
col = read_file(args[1])
words = read_file(args[2])
master = list(collaborators = col, words = words) #putting all data in a 'master' list 

#reformating the two strings into lists, where the ith element is a vector of collaborators/words for the ith abstract
for (i in 1:2) {                                                 #for each text object...
  master[[i]] = str_split(master[[i]], pattern="\n\n")[[1]] %>%  #each line becomes an element of a list
    lapply(str_split, pattern="\t") %>%                          #each element of the list (line of text) is split by tab characters into to a vector of strings
    lapply('[[', 1)                                              #removing unnecesary nesting
  
    orderA = lapply(master[[i]], function(x) x[1])  %>%          #getting ordering of lists by abstract                           
    unlist() %>%
    order()
  
  master[[i]] = master[[i]][orderA] %>%                          #sorting lists by abstract so indices match up (i.e. the ith element of master[[1]] and master[[3]] refer to collaborators and description words of the same abstract)  
    lapply(function(x) x[-1])                                    #removing abstract name element (as we have no more use for it)

  
}



##frequency table for collaborators##
colTable = master[[1]] %>% 
  lapply(str_replace_all, " ", "") %>%    #many collabroators are missing spaces in some abstracts but not in others, and thus white space will be removed so the same collaborator isn't accidently treated as different collaborators   
  lapply(unique) %>%                      #removing repeat collaborators from each abstract, as we only want the # of abstracts associated with each collaborator
  unlist() %>%                            #transforming from list to vector of collaborators so the table() function can be used
  table() %>%                             #table of collaborator frequences (gives # of abstracts where each collaborator appeared)
  as.tibble() %>%                         #turing into tibble so that functions from 'dplyr' package can be applied
  arrange(desc(n)) %>%                    #sorting collaborators in descending order by frequency
  filter(!str_detect(.,"(universityofnorthcarolina)|(unc)|(lineberger)"))   #removing UNC-affiliated collaborators (we don't care if UNC collaborates the most with its own hospital, for example)



##frequency table for words##
wordFreqTable = master[[2]] %>%
  lapply(unique) %>%                     #we want the # of abstracts where each word appears, not the # of words that appear overall. Thus, we don't want any word to be counted more than once in each abstract.
  unlist() %>%                           #transforming from list to vector of words so table() can be used
  table() %>%                            #table of word frequences (gives # of abstracts where each word appeared)
  as.tibble() %>%                        #turing into tibble so that functions from 'dplyr' package can be applied
  arrange(desc(n)) %>%                   #sorting words in descending order by frequency
  filter(!(. %in% c("", " ")))           #removing "words" that are just whitespace 



##frequency table for words, for each collaborator##

#function that gets word frequencies for abstracts with an inputted collaborator name (without whitespace)
getWords = function(col) {
  
  #a boolean vector with the ith element TRUE iff the inputted collaborator (after removing whitespace) is in the ith abstract
  hasCol = master[[1]] %>%                         
    lapply(str_replace_all, " ", "") %>%     
    str_detect(col)                         
  
  wordTable = master[[2]] %>%
    subset(hasCol) %>%                       #returns words in abstracts where hasCol is TRUE (i.e. where inputted collaborator is present)
    unlist() %>%                             
    table() %>%                              
    as.tibble() %>%
    arrange(desc(n)) %>%
    filter(!(. %in% c("", " "))) %>%
    filter(row_number() <= 100)              #to save space, memory and time, only the top 100 words will be kept
  
  
  return(wordTable)
}

#getting word frequencies for the top 10 collaborators
wordsByCol = vector("list", 10)                                      #the ith element of this list will be a word frequency table for abstracts with the ith top collaborator
for (i in 1:10) {                                                   
  wordsByCol[[i]] = suppressWarnings(getWords(colTable$.[i]))                                             
}

#getting the data from a list of data matrices to a single data matrix - each row giving the frequency (third column) of a word (second column) in abstracts with a particular collaborator (first column)
wordsData = unlist(wordsByCol)                                                #this new named vector has a combination of words and frequencies                                       
frequencies = ifelse(str_detect(names(wordsData), "n\\d"), wordsData, NA)     #frequencies have 'n' in their names
frequencyValid = sum(str_can_be_numeric(frequencies) | is.na(frequencies)) == length(frequencies) #a boolean that's TRUE iff all elements in 'frequencies' can be converted to numeric (or are missing) 
if (frequencyValid == F) stop("FREQUENCIES INVALID")                          #checking that we only have valid numeric frequencies, and throws error otherwise 
words = ifelse(str_detect(names(wordsData), "\\.\\d"), wordsData, NA)         #words have '.' in their names  
frequencies = frequencies[!is.na(frequencies)]                                #Each word in the 'words' vector will correspond to the frequency in the 'frequencies' vector at the same index, after removing NA values
words = words[!is.na(words)]      

           
#getting collaborators associated with the words and frequencies in the 'words' and 'frequencies' vectors
collaborators = vector("character", length(words)/2)                          
numWords = lapply(wordsByCol, nrow) %>% unlist()               
j=0
for (i in 1:10) {                                             
  collaborators[seq(j+1, j+numWords[i])] = rep(colTable$.[i], numWords[i])  #what's going on here is a bit complicated, but all you need to know is that the ith collaborator in this vector wil correspond to the ith word/frequency in the 'words' and 'frequencies' vectors v
  j = j + numWords[i]
}     

#single data matrix where the third column gives frequencies for the words in the second column for abstracts involving institutions in the first column           
wordsTableStrat = data.frame(frequencies, words, collaborators)



##saving data sets in the form of csvs (NOTE: Saving as .rds files would be easier, but the instructions said csv data only)##
write.csv(wordFreqTable, "wordsN.csv")
write.csv(colTable, "collaboratorsN.csv")
write.csv(wordsTableStrat, "wordsByCol.csv")
