library(stringr)
library(readr)

# a function that outputs a list containing a string of tab-separated values of collaborators and a string of tab-separated words appearing in the description, given an inputted abstract
processData = function(str) {
  
  str = str %>%
    toString() %>% 
    tolower() #we wish to ignore case
  
  
  
  ##getting vector of collaborating institutions##
  positions = str_locate(str, "author information:[^\\n]+")
  collabString = str_sub(str, positions[1], positions[2])         #getting part of string with author information 
  collabList = str_split(collabString, "(.|;)[\\s]?\\([\\d]+\\)") #splitting string into a list of collaborators - each collaborator is divided by a period or colon, followed by a possible space, followed by a one or two digit number in parentheses
  collabList = collabList[[1]][-c(1)]                             #removing the first element, which just says "author information:", and turning the remaining list ino a vector
  
  #algorithm to extract institution name from a collaborator in 'collabList' (right now, institution names are hidden in between department names, author names and insitution addresses)
  getInstitution = function(x) {
    keyWords = c("university", "hospital", "agency", "clinic", "institute", "centre", "center", "ltd", "college", "school", "organization", "organisation")
    for (i in 1:length(keyWords)) {
      if (str_detect(x, keyWords[i])) {                   
        wordPlace = str_locate(x, keyWords[i])[1,1]         #this is where part og the institution name is location on the string  
        commaPlaces = str_locate_all(x, '[,.]')[[1]][,1]    #all locations of commas and periods (institution names are separated from department names and addresses by commas or periods)
        if (length(commaPlaces)==0) return(x)               #return the whole string if there are no commas or periods
        begin=0
        end=str_length(x)+1
        for (j in 1:length(commaPlaces)) {                  #finding the location of the nearest commas/periods to the left/right of the institution keyword 
          if (commaPlaces[j] < wordPlace) begin=commaPlaces[j]
          if (commaPlaces[j] > wordPlace) {
            end=commaPlaces[j]
            break
          } 
        }
        i=length(keyWords)+1
        return(str_sub(x, begin+1, end-1))                  #return the substring between the commas left/right of the institution keyword (i.e. the entire institution name)
      }
    }
    return(paste("NOT DETECTED / OTHER:", x))               #if no institution key words were detected, just return the whole string with a message that the algorithm didn't detect any key words
  }
  
  collabName = lapply(collabList, getInstitution)           #getting list of institution names associated with the abstract
  
  
  
  ##getting vector of unique words in the abstract's description
  authorPos = positions[2]                          #last position in the "author information" line before a new line
  newLines = str_locate_all(str, "\\n")[[1]][,1]    
  linesAfterAuth = newLines[newLines>authorPos]    
  rightLine = linesAfterAuth[1]+1                           #first new line after "author position:"
  stop = ifelse(length(linesAfterAuth) > 1, linesAfterAuth[2]-1, str_length(str)) #returns the position of the next line after 'rightLine' if it exists, and the position of the end of the string otherwise
  descrip = str_sub(str, rightLine, stop)                   #description starts on the line after "author information", and stops either at end of the string or at any lines afterwords
  descrip = str_replace_all(descrip, "[.,;:\"]", " ")       #removing punctuation ("it" and "it." are the same words)
  words=str_split(descrip, "\\s")[[1]]                      #splits description into vector of words (separated by spaces)
  unqWords = unique(words)                                  #removes words that are repeated 

  
  ID = toString(args[1])          #making an ID (the file name) that can uniquely map vectors to the associated abstract
  collabName = c(ID, collabName) 
  unqWords = c(ID, unqWords)      #putting ID into vectors

  collabReformat = paste(collabName, collapse = "\t")      #turning both vectors into strings, each element separated by tabs
  wordReformat = paste(unqWords, collapse = "\t")
  
  return(list(collabReformat, wordReformat))
}


#extracting collaborator and word data
args = commandArgs(trailingOnly = TRUE)
str = readChar(args[1], file.info(args[1])$size)   
lista = processData(str)                           

#creating file names for the data to be saved as
fileNameCollab = paste(toString(args[1]), ".collaborators.txt", sep="")
fileNameWords = paste(toString(args[1]), ".words.txt", sep="")

#writing the data into .txt files
write(lista[[1]], fileNameCollab)
write(lista[[2]], fileNameWords)
