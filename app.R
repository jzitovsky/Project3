#loading/reading in data and required packages
library(shiny)
library(tidyverse)
library(magrittr)
library(DT)
library(tm)
library(wordcloud)
colN = read.csv("collaboratorsN.csv")
wordsN = read.csv("wordsN.csv")
wordsCol = read.csv("wordsByCol.csv")

#changing column names and adding spaces to collaborator names for 'colN' table (to improve readability in figures)
colN = colN %>% select('.', n)                    #removing a column that gives the row number
colnames(colN) = c("collaborators", "abstracts")  

colN = colN %>% 
  filter(row_number() <= 25) %>%               
  mutate(collaborators = factor(.$collaborators, labels = c("Baylor College of Medicine", "Brightam and Women's Hosptial", "Harvard School of Public Health", "Cornell University", 
                                                            "Dana-Farber Cancer Institute", "Duke University", "Duke University Medical Center", "Duke School of Medicine", 
                                                            "Emory University", "Fred Hutchington", "Harvard Medical School", "Mayo Clinic", "Memorial Sloan Kettering", 
                                                            "National Cancer Institute", "Northwestern University", "Roswell Park Cancer Institute", "MD Anderson Cancer Center", 
                                                            "University of California", "University of Chicago", "University of Minnesota", "University of Southern California", 
                                                            "University of Toronto", "University of Washington", "Vanderbilt University", "Washinton University")))

#getting top 10 collaborators (will be needed for shiny app) 
top10Factor = colN %>% 
  filter(row_number()<=10) %>% 
  select(collaborators) %>%
  unlist()                             #top 10 collaborators as vector of factors     

top10 =  as.character(top10Factor)
top10 = c("All", top10)
names(top10) = top10
top10 = as.list(top10)                 #named list of top 10 collaborators together with "All" string

#changing column names and adding spaces to collaborator names for other tables
wordsCol = select(wordsCol, collaborators, words, frequencies)        #removing a column that gives the row number
colnames(wordsCol)[3] = "abstracts"                                   
levels(wordsCol$collaborators) = levels(factor(top10Factor))          #collaborator names will be the same as those created above

wordsN = wordsN %>%
  select('.', n)                                                      #removing a column that gives the row number
colnames(wordsN) = c("words", "abstracts")

#creating subset of generic/garbage words (e.g. 'the') that appear in the absracts' descriptions (will be needed for shiny app)
unimportant = c(stopwords("SMART"), "=", "1", "0", "2", "3", "4", "including", "6", "<", "(1", "5", "(hr", "(p", "12", "02)", "7", "(or", "15", "(n", "001)", "8")


#building a string that will be the main text (description) of the shiny app
line1 = "The figures below are based on 441 recent abstracts involving UNC in cancer-related fields provided by Dr. Biggs. The first figure shows the institutions that collaborated with UNC on the greatest number of abstracts, and plots the number of abstracts that each top institution collaborated in via barplot. By default, the top 10 collaborators are graphed. However, one can adjust the barplot to include anywhere from the top 1 to the top 20 collaborators, by inserting an integer from 1 to 20 in the box below 'Number of collaborators to show'. The second figure is a table giving the 100 words that most frequently appear in abstracts, together with the number of abstract appearances for each word. By default, certain words are hidden, such as 'the'. However, filtering is subjective, and what I find to be relevant someone else may find irrelevant, and vice versa. To see all 100 words without filter, uncheck the box at the top corner of the figure titled 'Hide generic words'. One can also see the top words appearing in abstracts associated with a particular collaborator, by selecting a collaborator from the drop-down menu titled 'Collaborators'. Lastly, the filtered word frequencies are plotted in Figure 3 via a word cloud, with words in larger font representing words that appear more frequently in abstracts. Like in Figure 2, one can get plots of word frequencies for each collaborator using a drop-down menu. There is also an option to restrict the maximum words plotted, by moving the slider titled 'Maximum words'."

line2 = "Note that collaborating institutions may be treated as separate if they are cited differently and enjoy autonomy from each other, even if they are subsidiaries of the same underlying body. For example, those affiliated with Duke Medical School often say they are affiliated with 'Duke School of Medicine' (and do NOT specifically put 'Duke University' as part of the affiliation) while those affiliated with almost every other department/school of Duke normally say they are affiliated with 'Duke University'. As the school of medicine is cited differently from other departments/schools of Duke, and as the Duke School of Medicine enjoys a particularly large amount of autonomy compared to other Duke departments/schools regarding its faculty, funding, research goals and administration decisions, we treat 'Duke School of Medicine' as a separate collaborator from 'Duke University'. Similar logic applies to the  hospital of Duke compared to the medical school of Duke,, as well as well as Harvard SPH and Harvard Medical School."


#creating shiny app
shinyApp(
  #creating user interface
  ui = fluidPage(
    titlePanel("Collaborators and Word Frequencies of Recent UNC Abstracts"),     #title of shiny app
    mainPanel(HTML(paste(line1,'<br/>', '<br/>', line2)), width="100px"),         #desciption of shiny app
    br(), br(),                                                                   #adding space between the description and figure
    
    #Controls for first figure: Barplot of top collaborators
    fluidRow(column(12,                                                           
                    div(style = "font-size:25px;",'Figure 1: Top Collaborators')),    #title of figure
	     br(),
             column(12, 
                    numericInput(inputId = "colNum",                                  #a numeric input that will control the number of collaborators plotted in the barplot
                                 label = "Number of collaborators to show (give an integer between 1 and 20):",
                                 value = 10,
                                 min = 1,
                                 max = 20,
                                 width='550px'),
                    hr(), 
                    plotOutput('x1'))),                                               #barplot output
    br(), br(),                                                                       #adding space between the figures
    
    #Controls for second figure: Word frequency table
    fluidRow(column(12, 
                    div(style = "font-size:25px;",'Figure 2: Most-Used Words')),     #title of figure
             br(),
             column(4, 
                    selectInput(inputId = "colInput",                                #a drop-down menu of collaborators - when a collaborator is selected, a word frequency table gets generated based on abstacts involving that collaborator
                                label = "Collaborator:",
                                choices = top10)),
             column(3, offset=5,
                    checkboxInput(inputId = "filter",                                 #a check box that will control whether generic words (e.g. 'the') get filtered out
                                  label = "Hide generic words",
                                  value = T)),
             column(12, hr(), DTOutput('x2'))),                                       #table output
    br(), br(),
    
    #Controls for the third figure: Word cloud
    fluidRow(column(12, 
                    div(style = "font-size:25px;",'Figure 3: Word Cloud')),           #title of figure
	     br(),
             column(4, 
                    sliderInput(inputId = "maxWords",                                 #a slider that will control the maximum words allowed on the plot
                                label = "Maximum words:",
                                min=1,
                                max=50,
                                value=100)),
             column(4, offset = 4, 
                    selectInput(inputId = "colInput2",                                #a drop-down menu of collaborators - when a collaborator is selected, a word cloud gets plotted based on abstacts involving that collaborator
                                label = "Collaborator:",
                                choices = top10)),
             column(12, hr(), plotOutput('x3', width='100%', height=500))),           #word cloud output with enlarged height (so words don't get cut off)
    br(), br(), br(), br(), br(), br(), br(), br(), br(),  br(), br(), br(), br(), br(), br(), br(), br(), br(),
    
    sidebarLayout(sidebarPanel(), mainPanel())
  ),
  
  
  
  #creating server
  server = function(input, output, session) {
    
    #by default, figure 2 will have all rows showing at once
    options(DT.options = list(pageLength = 100))                                         
    
    #rendering figure 1 barplot
    output$x1 = renderPlot({    
      ggplot(data = colN %>% 
               filter(row_number() <= 20) %>%         #at most 20 collaborators will be plotted (regardless of input)
               filter(row_number() <= input$colNum),  #further restricts number of collaborators in plot based on input
             aes(reorder(collaborators, abstracts),   #ordering collaborators by frequency
                 abstracts, 
                 fill=collaborators)) +               #giving each bar a different color
        geom_bar(stat = "identity") +                 #plotting bar geom
        guides(fill=FALSE) +                          #removing legend (we know which bar is for which collaborator via the y-axis)
        xlab("Collaborators") +                        #improving axes lables
        ylab("Number of Abstracts") + 
        coord_flip()                                  #making barplot horizontal
    })
    
    #rending figure 2 table
    output$x2 = renderDT({
      if (input$colInput == "All") {               
        wordsN %>%                             #if "all" option of slide-down menu is selected (default), print overall word frequencies
          filter(row_number() <= 100) %>%      #select top 100 words
          { if(input$filter) filter(., !(words %in% unimportant)) else . } #if filter checkbox is checked, filter out undesired/generic/unimportant words (e.g. 'the', numbers etc.)
      }
      else {
        wordsCol %>%                           
          filter(collaborators == input$colInput) %>%                       #if "all" option of slide-down menu is not selected, only abstracts involving the selected collaborator is used
          select(words, abstracts) %>%                                      #remove table saying the collaborator
          filter(row_number() <= 100) %>%                                   #select top 100 words
          { if(input$filter) filter(., !(words %in% unimportant)) else . }  #if filter checkbox is checked, filter out undesired words
      }
    })
    
    #rendering figure 3 word cloud
    wordsNFilter = filter(wordsN, !(words %in% unimportant))       # 'wordsN' excluding generic/garbage words
    wordsColFilter = filter(wordsCol, !(words %in% unimportant))   # 'wordsCol' excluding generic/garbage words 
    output$x3 = renderPlot({
      if (input$colInput2 == "All") {
        wordcloud(wordsNFilter$words, wordsNFilter$abstracts,       #if "all" option of slide-down menu is selected (default), use all abstracts for plot
                  max.words = input$maxWords,                       #max words displayed based on slider input
                  colors = brewer.pal(8, "Dark2"))                  #give words different colors (improves readability
      } 
      else {
        wordcloud(filter(wordsColFilter, collaborators == input$colInput2)$words,  #if "all" option is not selected, only uses abstracts involving selected collaborator when plotting
                  filter(wordsColFilter, collaborators == input$colInput2)$abstracts,
                  max.words = input$maxWords,
                  colors = brewer.pal(8, "Dark2"))
      }
    })   
  }
)
