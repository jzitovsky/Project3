library(tidyverse)
library(magrittr)

#reading in three text files where each new line represents another abstract, and tabs separate words/collaborators within abstracts
args = commandArgs(trailingOnly = TRUE)
col = read_file(args[1])
words = read_file(args[2])
unqWords = read_file(args[3])
master = list(collaborators = col, words = words, uniqueWords = unqWords) #putting all data in a 'master' list 

#reforming the three text objects into lists, where the ith element is a vector of collaborators/words for the ith abstract
for (i in 1:3) {                                                 #for each text object...
  master[[i]] = str_split(master[[i]], pattern="\n\n")[[1]] %>%  #each line becomes an element of a list
    lapply(str_split, pattern="\t") %>%                          #elements transformed from a line of text to a vector of strings separated by tabs
    lapply('[[', 1) %>%                                          #removing unnecesary nesting
    lapply(function(x) x[-1])                                    #first element of each vector is the abstract name, which can be removed
}



##frequency table for collaborators##
colTable = master[[1]] %>% 
  lapply(str_replace_all, " ", "") %>%    #many collabroators are missing spaces in some abstracts and noto thers, and thus white space is removed so the same collaborator isn't treated as multiple collaborators   
  lapply(unique) %>%                      #we want the # of abstracts associated with each collaborator, thus we don't want collaborators for any abstract to be counted more than once
  unlist() %>%                            #transforming from list to vector of collaborators so the table() function can be used
  table() %>%                             #table of collaborator frequences (gives # of abstracts where each collaborator appeared)
  as.tibble() %>%                         #turing into tibble so that functions from 'dplyr' package can be applied
  arrange(desc(n)) %>%                    #sorting collaborators in descending order by frequency
  filter(!str_detect(.,"(universityofnorthcarolina)|(unc)|(lineberger)"))   #removing UNC-affiliated collaborators (we don't care if UNC collaborates the most with its own hospital, for example)



##frequency table for words##
wordFreqTable = master[[3]] %>%
  lapply(unique) %>%                     #we want the # of abstracts where each word appears, not the # of words that appear overall. Thus, we don't want any word to be counted more than once in each abstract.
  unlist() %>%                           #transforming from list to vector of words so table() can be used
  table() %>%                            #table of word frequences (gives # of abstracts where each word appeared)
  as.tibble() %>%                        #turing into tibble so that functions from 'dplyr' package can be applied
  arrange(desc(n)) %>%                   #sorting words in descending order by frequency
  filter(!(. %in% c("", " ")))           #removing 'words' that are just whitespace

#filtering out words that are not subject-related or study-related 
unimportant = c("of", "the", "and", "to", "in", "a", "with", "for", "is", "were", "was", "we", "that", "this", "by", "from", 
                "as", "on", "or", "are", "an", "at", "these", "be", "between", "which", "among", "but", "than", "after", "our", "their", 
                "into", "not", "1", "0", "=", "2", "3", "have", "using", "=", "may", "2", "has", "however", "3", "had", "who", "no", 
                "more", "all", "used", "high", "overall", "also", "not")

wordsFiltered = wordFreqTable %>%                            
  filter(!(. %in% unimportant)) 



##frequency table for words, for each collaborator##

#function that gets word frequencies for abstracts with an inputted collaborator name (without whitespace)
getWords = function(col) {
  
  #a boolean vector with the ith element TRUE iff the inputted collaborator (after removing whitespace) in the ith abstract
  hasCol = master[[1]] %>%                   #getting list of collaborators for each abstract        
    lapply(str_replace_all, " ", "") %>%     #remove whitespace
    str_detect(col)                          #detects whether or not the inputted string is in each element of master[[1]] 
  
  wordTable = master[[3]] %>%
    subset(hasCol) %>%                       #returns words in abstracts where hasCol is TRUE
    unlist() %>%                             
    table() %>%                              
    as.tibble() %>%
    arrange(desc(n)) %>%
    filter(!(. %in% c("", " "))) %>%
    filter(row_number() <= 100)              #to save space, only the top 100 words will be kept
  
  
  return(wordTable)
}

#getting word frequencies for the top 10 collaborators
wordsByCol = vector("list", 10)                                      #the ith element of this list will be a word frequency table for abstracts with the ith top collaborator
filteredByCol = vector("list", 10)                                   #the ith element of this list will be a medical and subject-realted word frequency table for abstracts with the ith top collaborator
for (i in 1:10) {                                                   
  wordTable = suppressWarnings(getWords(colTable$.[i]))              
  wordsByCol[[i]] = wordTable                                        #word frequency table for abstracts with collaborator i
  filteredByCol[[i]] = wordTable[!(wordTable$. %in% unimportant),]   #filtering out words that are not subject and study-related
}



##saving data sets in the form of csvs (NOTE: Saving as an .rds file would be easier, but the instructions specified that Nextflow output csv data##

#saving unstratified data sets
write.csv(wordFreqTable, "wordsN.csv")
write.csv(wordsFiltered, "filterWordsN.csv")
write.csv(colTable, "collaboratorsN.csv")

#saving all 20 data sets of words and filtered words by each of the top 10 collaborators
for (i in 1:10) {
  title1 = paste("words", toString(i), ".csv", sep="")
  write.csv(wordsByCol[[i]], title1)
  title2 = paste("filteredWords", toString(i), ".csv", sep="")
  write.csv(filteredByCol[[i]], title2)
}
