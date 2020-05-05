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
IN_DEBUG_MODE   <- FALSE
SEED_VALUE      <- FALSE
BASEDIR <- file.path("~","Workspace", "doctorate", "projects")
LIBDIR  <- file.path(BASEDIR, "lib", "R")
PRJDIR  <- file.path(BASEDIR, "long-lived-bug-prediction")
SRCDIR  <- file.path(PRJDIR, "R")
DATADIR <- file.path(PRJDIR, "notebooks", "datasets")
FIGDIR <- file.path(PRJDIR, "notebooks", "datasets")

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
processors <- ifelse(IN_DEBUG_MODE, 4, 4)
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
  tdm     <- tm::TermDocumentMatrix(corpus, control=list(weighting=weightTfIdf)) 
  tdm     <- as.matrix(tdm)
  tdm     <- sort(rowSums(tdm), decreasing=TRUE)
  tdm     <- data.frame(word=names(tdm), freq=tdm)
  return (head(tdm, .n))
}

# main function
for (project.name in c('eclipse', 'freedesktop', 'gnome', 'gcc', 'mozilla', 'winehq'))
{
  flog.trace("reading data files of %s project", project.name)
  reports.path <- file.path(DATADIR, sprintf("20190917_%s_bug_report_data.csv", project.name))

  reports.data <- read_csv(reports.path, na  = c("", "NA"))

  column.names <- c('bug_id', 'short_description', 'long_description', 'bug_fix_time')
  reports.data <- subset(reports.data , bug_fix_time >= 0)[, column.names]
  
  if (IN_DEBUG_MODE){
    flog.trace("DEBUG_MODE: Sample bug reports dataset")
    set.seed(SEED_VALUE)
    reports.data <- sample_n(reports.data, 1000) 
  }
  
  for (feature.name in c('short_description', 'long_description'))
  {
  
    # feature engineering. 
    reports.featured <- reports.data[, c('bug_id', feature.name, 'bug_fix_time')]
    reports.featured <- reports.featured[complete.cases(reports.featured), ]
    
    flog.trace("cleaning text features")
    reports.featured[feature.name]  <- clean_text(reports.featured[feature.name])
    
  
    set.seed(SEED_VALUE)
    flog.trace("making document term matrix for long-lived bugs on %s of %s"
               , feature.name
               , project.name)
    long.lived.bugs <- subset(reports.featured, bug_fix_time > 365) 
    long.lived.dtm   <- make_tdm(long.lived.bugs[, c('bug_id', feature.name)], 100)
    
    set.seed(SEED_VALUE)
    flog.trace("making document term matrix for short-lived bugs on %s of %s"
               , feature.name
               , project.name)
    short.lived.bugs    <- subset(reports.featured, bug_fix_time <= 365) 
    short.lived.dtm     <- make_tdm(short.lived.bugs[, c('bug_id', feature.name)], 100)
    
    set.seed(SEED_VALUE)
    flog.trace("plotting wordcloud for short-lived bugs on %s of %s"
               , feature.name
               , project.name)
    png(file.path(FIGDIR, sprintf("rq2-%s-wordcloud-%s-short-lived.png", project.name, feature.name))
        , width = 700, height = 700)
    wordcloud(words=short.lived.dtm$word
              , scale=c(5, .3)
              , freq=short.lived.dtm$freq
              , min.freq=0
              , max.words=100
              , random.order=FALSE
              , rot.per=0.35
              , colors=brewer.pal(8, "Dark2"))
    dev.off()
  
    set.seed(SEED_VALUE)
    flog.trace("plotting wordcloud for long-lived bugs on %s of %s", feature.name, project.name)
    png(file.path(FIGDIR, sprintf("rq2-%s-wordcloud-%s-long-lived.png", project.name, feature.name))
        , width = 700, height = 700)
    wordcloud(words=long.lived.dtm$word
              , scale=c(5, .3)
              , freq=long.lived.dtm$freq
              , min.freq=0
              , max.words=100
              , random.order=FALSE
              , rot.per=0.35
              , colors=brewer.pal(8, "Dark2"))
    dev.off()
  }
}
flog.trace("processing finished")
