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

#changing column names and adding spaces to collaborator names for 'colN' table (improve readability in figures)
colN = colN %>% select('.', n)
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
  unlist()
top10 =  as.character(top10Factor)
top10 = c("All", top10)
names(top10) = top10
top10 = as.list(top10)

#changing column names and adding appropiate spaces for other tables
wordsCol = select(wordsCol, collaborators, words, frequencies)
colnames(wordsCol)[3] = "abstracts"
levels(wordsCol$collaborators) = levels(factor(top10Factor))
wordsN = wordsN %>%
  select('.', n) 
colnames(wordsN) = c("words", "abstracts")

#creating subset of appearing "generic" words not directly related to medicine (will be needed for shiny app)
unimportant = c(stopwords("SMART"), "=", "1", "0", "2", "3", "4", "including", "6", "<", "(1", "5", "(hr", "(p", "12", "02)", "7", "(or", "15", "(n", "001)", "8")


#building a string that will be the main text (description) of the shiny app
line1 = "The figures below are based on 441 recent UNC abstracts in cancer-related fields provided by Dr. Biggs. The first figure gives the collaborating institutions that were involved with the greatest number of abstracts, and plots the number of abstracts involving each top collaborator via barplot. By default, the top 10 collaborators are graphed. However, one can adjust the barplot to include anywhere from the top 1 to the top 20 collaborators, by inserting an integer from 1 to 20 in the box below 'Number of collaborators to show'. The second figure is a table giving the 100 words that most frequently appear in abstracts, together with the number of abstract appearences for each word. By default, very generic words such as 'the' and 'have' are hidden. However, filtering is subjective, and what I find to be relevant someone else may find irrelevant, and vice versa. To see all 100 words without filter, uncheck the box at the top corner of the figure titled 'Hide generic words'. One can also see the top words appearing in abstracts associated with a particular collaborator, by selecting a collaborator from the drop-down menu titled 'Collaborators'. Lastly, the filtered word frequencies are plotted in Figure 3 via a word cloud, with words in larger font representing words that appear more frequently in abstracts. Like in Figure 2, one can get plots of word frequencies for each collaborator using a drop-down menu. There is also an option to restrict the maximum words plotted, by moving the slider titled 'Maximum words'."
line2 = "Note that collaborating instiutions may be treated as separate if they are cited differently and enjoy autonomy from each other, even if they are subsidiaries of the same underlying body. For example, those affiliated with Duke Medical School often say they are affiliated with 'Duke School of Medicine' (and do NOT specifically put 'Duke University' as part of the affiliation) while those affiliated with almost every other department/school of Duke normally say they are affiliated with 'Duke University'. As the school of medicine is cited differently from other departments/schools of Duke, and as the Duke School of Medicine enjoys a parcularly large amount of autonomy compared to other Duke departments/schools regarding its faculty, funding, research goals and administration decisions, we treat 'Duke Medicine' as a separate collaborator from 'Duke University'. Similar logic applies to the medical school of Duke and the hospital of Duke, as well as well as Harvard SPH and Harvard Medical School."
description = paste(line1, line2, sep="\n\n\n\n\n\n")


#creating shiny app
shinyApp(
  ui = fluidPage(
    titlePanel("Word Frequencies and Collaborators of Recent UNC Abstracts"),
    mainPanel(HTML(paste(line1,'<br/>', '<br/>', line2)), width="100px"), 
    br(), br(),
    
    fluidRow(column(12, 
                    div(style = "font-size:25px;",'Figure 1: Top Collaborators')),
             column(12, 
                    numericInput(inputId = "colNum",
                                 label = "Number of collaborators to show (give an integer between 1 and 20)",
                                 value = 10,
                                 min = 1,
                                 max = 20,
                                 width='550px'),
                    hr(), 
                    plotOutput('x1'))),
    br(), br(),
    
    fluidRow(column(12, 
                    div(style = "font-size:25px;",'Figure 2: Most-Used Words')),
             column(4, 
                    selectInput(inputId = "colInput",
                                label = "Collaborator",
                                choices = top10)),
             column(3, offset=5,
                    checkboxInput(inputId = "filter",
                                  label = "Hide words not related to research subjects/studies",
                                  value = T)),
             column(12, hr(), DTOutput('x2'))),
    br(), br(),
    
    fluidRow(column(12, 
                    div(style = "font-size:25px;",'Figure 3: Word Cloud')),
             column(4, 
                    sliderInput(inputId = "maxWords",
                                    label = "Maximum words:",
                                    min=1,
                                    max=50,
                                    value=100)),
             column(4, offset = 4, 
                    selectInput(inputId = "colInput2",
                                label = "Collaborator",
                                choices = top10)),
             column(12, hr(), plotOutput('x3', width='100%', height=450))),
    br(), br(), br(), br(), br(), br(), br(), br(), br(),  br(), br(), br(), br(), br(), br(), br(), br(), br(),
                    
             
    
    sidebarLayout(sidebarPanel(), mainPanel())
    
  ),
  
  
  
  server = function(input, output, session) {
    
    options(DT.options = list(pageLength = 100))
    
    output$x1 = renderPlot({    
      ggplot(data = colN %>% 
               filter(row_number() <= 20) %>%
               filter(row_number() <= input$colNum), 
             aes(reorder(collaborators, abstracts), abstracts, fill=collaborators)) + 
        geom_bar(stat = "identity") + 
        guides(fill=FALSE) + 
        xlab("Collaborator") + 
        ylab("Number of Abstracts") + 
        coord_flip()
    })
    
    output$x2 = renderDT({
        if (input$colInput == "All") {
          wordsN %>%
            filter(row_number() <= 100) %>%
            { if(input$filter) filter(., !(words %in% unimportant)) else . } 
        }
          else {
          wordsCol %>%
            filter(collaborators == input$colInput) %>%
            select(words, abstracts) %>%
            filter(row_number() <= 100) %>%
            { if(input$filter) filter(., !(words %in% unimportant)) else . } 
        }
      })
    filter = filter(wordsN, !(words %in% unimportant))
    par(mar=c(7,8,7,7))
    output$x3 = renderPlot(
      {wordcloud(filter$words, filter$abstracts, 
                 max.words=input$maxWords,
                 colors = brewer.pal(8, "Dark2"))}
    )
  }
)
