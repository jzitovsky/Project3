library(stringr)
library(readr)

# a function that outputs a list containing a vector of collaborating authors and a vector of words appearing in the description from an inputted abstract
processData = function(str) {
  
  str = str %>%
    toString() %>%
    tolower() #we wish to ignore case
  
  positions = str_locate(str, "author information:[^\\n]+")
  collab = str_sub(str, positions[1], positions[2]) #getting part with author information
  collab2 = str_split(collab, "(.|;)[\\s]?\\([\\d]+\\)") #each author of a new institution is divided by semi-colon or colon, followed by a number in parentheses
  collab2 = collab2[[1]][-c(1)] #we don't care about the part that says "author information:"
  
  #algorithm to get company name
  getCompany = function(x) {
    keyWords = c("university", "hospital", "agency", "clinic", "institute", "centre", "center", "ltd", "college", "school", "organization", "organisation")
    for (i in 1:length(keyWords)) {
      if (str_detect(x, keyWords[i])) {
        wordPlace = str_locate(x, keyWords[i])[1,1]
        commaPlaces = str_locate_all(x, '[,.]')[[1]][,1]
        if (length(commaPlaces)==0) return(x) #return the whole string if there are no commas or periods
        begin=0
        end=str_length(x)+1
        for (j in 1:length(commaPlaces)) {
          if (commaPlaces[j] < wordPlace) begin=commaPlaces[j]
          if (commaPlaces[j] > wordPlace) {
            end=commaPlaces[j]
            break
          } 
        }
        i=length(keyWords)+1
        return(str_sub(x, begin+1, end-1))
      }
    }
    return(paste("NOT DETECTED / OTHER:", x))
  }
  
  collab3 = lapply(collab2, getCompany) #getting company name
  
  newLines = str_locate_all(str, "\\n")[[1]][,1]
  authorPos = positions[2] #position of "author information:"
  linesAfterAuth = newLines[newLines>authorPos]
  rightLine = linesAfterAuth[1]+1 #first new line after "author position":
  stop = ifelse(length(linesAfterAuth) > 1, linesAfterAuth[2]-1, str_length(str))
  descrip = str_sub(str, rightLine, stop) #description starts on the line after "author information", and stops either at end or at any lines afterwords
  descrip = str_replace_all(descrip, "[.,;:\"]", " ")
  words=str_split(descrip, "\\s")[[1]] 
  unqWords = unique(words) #vector of (unique) words
  #lots of spaces not recorded in descriptions...
  
  ID = toString(args[1])  #making an ID (the file name)  that uniquely maps to the abstract
  collab3 = c(ID, collab3) 
  unqWords = c(ID, unqWords) #putting ID into lists

  collabReformat = paste(collab3, collapse = "\t")
  wordReformat = paste(unqWords, collapse = "\t")
  
  return(list(collabReformat, wordReformat))
}


#extracting collaborator and word data
args = commandArgs(trailingOnly = TRUE)
str = readChar(args[1], file.info(args[1])$size)
lista = processData(str)

#creating names for the files to be created
fileNameCollab = paste(toString(args[1]), ".collaborators.txt", sep="")
fileNameWords = paste(toString(args[1]), ".words.txt", sep="")

#writing the data into .csv files
write(lista[[1]], fileNameCollab)
write(lista[[2]], fileNameWords)
