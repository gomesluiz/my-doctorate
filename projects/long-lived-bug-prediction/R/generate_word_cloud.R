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

source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))

flog.threshold(TRACE)
processors <- ifelse(IN_DEBUG_MODE, 3, 3)
r_cluster  <-  makePSOCKcluster(processors)
registerDoParallel(r_cluster)

#' @description 
#' Make a tdm with n terms from a text.
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
flog.trace("reading data files")
reports.path <- file.path(DATADIR, "20190917_gcc_bug_report_data.csv")
results.path <- file.path(DATADIR, "20190926143854_rq3e4_all_predict_long_lived_tests_balanced_acc.csv")

reports.data <- read_csv(reports.path, na  = c("", "NA"))
results.data <- read_csv(results.path, na  = c("", "NA"))

if (IN_DEBUG_MODE){
  flog.trace("DEBUG_MODE: Sample bug reports dataset")
  set.seed(144)
  reports.data <- sample_n(reports.data, 1000) 
  results.data <- sample_n(results.data, 1000) 
}

flog.trace("merging data files")
# merging reports and results dataframes.
reports.merged = merge(reports.data, results.data, by.x="bug_id", by.y="bug_id")

# feature engineering. 
reports.merged <- reports.merged[, c('bug_id', 'long_description', 'long_lived', 'y_hat')]
reports.merged <- reports.merged[complete.cases(reports.merged), ]
  
flog.trace("cleaning text features")
reports.merged$long_description  <- clean_text(reports.merged$long_description)

# filtering out long-lived correct predicted
flog.trace("making document term matrix for correct predicted bugs")
reports.merged         <- subset(reports.merged, long_lived=='Y') 
predicted.corrected    <- make_tdm(subset(reports.merged, y_hat=='Y', select=c(bug_id, long_description)), 100)

flog.trace("making document term matrix for incorrect predicted bugs")
predicted.incorrected  <- make_tdm(subset(reports.merged, y_hat=='N', select=c(bug_id, long_description)), 100)

flog.trace("plotting wordcloud for correct predicted bugs")
set.seed(144)
#png(file.path(DATADIR, "wordcloud-gcc-corrected-predicted-bugs.png"), width = 700, height = 700)
#wordcloud(words=predicted.corrected$word, scale=c(5, .3), freq=predicted.corrected$freq, min.freq=0,
#          max.words=100, random.order=FALSE, rot.per=0.35,
#          colors=brewer.pal(8, "Dark2"))
#dev.off()

flog.trace("plotting wordcloud for incorrect predicted bugs")
set.seed(144)
png(file.path(DATADIR, "wordcloud-gcc-incorrected-predicted-bugs.png"), width = 700, height = 700)
wordcloud(words=predicted.incorrected$word, scale=c(5, .3), freq=predicted.incorrected$freq, min.freq=0,
          max.words=100, random.order=FALSE, rot.per=0.35,
          colors=brewer.pal(8, "Dark2"))
dev.off()
flog.trace("processing finished")