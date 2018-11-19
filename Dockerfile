FROM rocker/tidyverse

RUN Rscript -e "install.packages('strex')"
RUN Rscript -e "install.packages('DT')"
RUN Rscript -e "install.packages('tm')"
RUN Rscript -e "install.packages('wordcloud')"
