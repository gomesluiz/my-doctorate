#' @description 
#'    generate the word cloud from long description of a bug report.
#'    
#' @author: 
#' Luiz Alberto (gomes.luiz@gmail.com)
#'
#' @usage: 
#' 
#' @details:
#'    2019-10-4    file created   gomes.luiz@gmail.com
#' 

# clean R Studio session.
rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)
timestamp  <- format(Sys.time(), "%Y%m%d%H%M%S")

# setup project folders.
IN_DEBUG_MODE  <- FALSE
BASEDIR <- file.path("~","Workspace", "doctorate", "projects")
LIBDIR  <- file.path(BASEDIR, "lib", "R")
PRJDIR  <- file.path(BASEDIR, "long-lived-bug-prediction")
SRCDIR  <- file.path(PRJDIR, "R")
DATADIR <- file.path(PRJDIR, "notebooks", "datasets")

if (!require('dplyr')) install.packages("dplyr")
if (!require('doParallel')) install.packages("doParallel")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require("ggplot2")) install.packages("futile.logger")
if (!require("qdap")) install.packages("qdap")
if (!require("SnowballC")) install.packages("SnowballC")
if (!require("tidyverse")) install.packages("tidyverse")
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm")
if (!require("wordcloud")) install.packages("wordcloud")
if (!require("RColorBrewer")) install.packages("RColorBrewer")

library(dplyr)
library(doParallel)
library(futile.logger)
library(qdap)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)
library(wordcloud)
library(RColorBrewer)
library(ggplot2)

source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))

flog.threshold(TRACE)
processors <- ifelse(IN_DEBUG_MODE, 3, 3)
r_cluster  <-  makePSOCKcluster(processors)
registerDoParallel(r_cluster)

#' @description 
#' Make a tdm with n terms from a text.
#' 
#' @param .docs The documents.
#' @param .n    Number of matrix terms.
#' 
#' @return The Term Document Matrix
#' 
make_tdm <- function(.docs, .n=100) {
  corpus  <- clean_corpus(.docs)
  tdm     <- TermDocumentMatrix(corpus, control=list(weighting=weightTfIdf)) 
  tdm     <- as.matrix(tdm)
  tdm     <- sort(rowSums(tdm), decreasing=TRUE)
  tdm     <- data.frame(word=names(tdm), freq=tdm)
  return (head(tdm, .n))
}

# main function
for (project.name in c('eclipse', 'freedesktop', 'gnome', 'gcc', 'mozilla', 'winehq'))
{
  for (feature.name in c('short_description', 'long_description'))
  {
    flog.trace("reading data files of %s project", project.name)
    reports.path <- file.path(DATADIR, sprintf("20190917_%s_bug_report_data.csv", project.name))
  
    reports.data <- read_csv(reports.path, na  = c("", "NA"))
    reports.data <- subset(reports.data, bug_fix_time >= 0)[, c(feature.name)]
    
    if (IN_DEBUG_MODE){
      flog.trace("DEBUG_MODE: Sample bug reports dataset")
      set.seed(144)
      reports.data <- sample_n(reports.data, 1000) 
    }
  
    flog.trace("cleaning text features")
    reports.merged[feature.name]  <- clean_text(reports.merged[feature.name])
    
    # filtering out long-lived correct predicted
    flog.trace("making document term matrix for correct predicted bugs")
    reports.merged         <- subset(reports.merged, long_lived=='Y') 
    predicted.corrected    <- make_tdm(subset(reports.merged, y_hat=='Y', select=c(bug_id, long_description)), 100)
  
    flog.trace("making document term matrix for incorrect predicted bugs")
    predicted.incorrected  <- make_tdm(subset(reports.merged, y_hat=='N', select=c(bug_id, long_description)), 100)
    
    flog.trace("plotting wordcloud for correct predicted bugs")
    set.seed(144)
    png(file.path(DATADIR, sprintf("wordcloud-%s-corrected-predicted-bugs.png", project.name)), width = 700, height = 700)
    wordcloud(words=predicted.corrected$word, scale=c(5, .3), freq=predicted.corrected$freq, min.freq=0,
              max.words=100, random.order=FALSE, rot.per=0.35,
              colors=brewer.pal(8, "Dark2"))
    dev.off()
  
    flog.trace("plotting histogram for correct predicted bugs")
    set.seed(144)
    png(file.path(DATADIR, sprintf("histogram-%s-corrected-predicted-bugs.png", project.name)), width = 700, height = 700)
    ggplot(data=predicted.corrected, aes(x=predicted.corrected$freq)) +
      geom_histogram()
    dev.off()
    
    flog.trace("plotting wordcloud for incorrect predicted bugs")
    set.seed(144)
    png(file.path(DATADIR, sprintf("wordcloud-%s-incorrected-predicted-bugs.png", project.name)), width = 700, height = 700)
    wordcloud(words=predicted.incorrected$word, scale=c(5, .3), freq=predicted.incorrected$freq, min.freq=0,
            max.words=100, random.order=FALSE, rot.per=0.35,
            colors=brewer.pal(8, "Dark2"))
    dev.off()
    
    flog.trace("plotting histogram for incorrect predicted bugs")
    set.seed(144)
    png(file.path(DATADIR, sprintf("histogram-%s-incorrected-predicted-bugs.png", project.name)), width = 700, height = 700)
    ggplot(data=predicted.incorrected, aes(x=predicted.incorrected$freq)) +
      geom_histogram()
    dev.off()
  }
}
flog.trace("processing finished")