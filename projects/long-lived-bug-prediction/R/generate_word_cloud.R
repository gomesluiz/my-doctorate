#' @description 
#'
#' @author: 
#' Luiz Alberto (gomes.luiz@gmail.com)
#'
#' @usage: 
#' 
#' @details:
#' 
#'         17/09/2019 16:00 pre-process in the train method removed
#' 

# clean R Studio session.
rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)
timestamp       <- format(Sys.time(), "%Y%m%d%H%M%S")

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

make_tdm <- function(.data, .n=100) {
  corpus  <- clean_corpus(.data)
  tdm     <- TermDocumentMatrix(corpus, control=list(weighting=weightTfIdf)) 
  tdm     <- as.matrix(tdm)
  tdm     <- sort(rowSums(tdm), decreasing=TRUE)
  tdm     <- data.frame(word=names(tdm), freq=tdm)
  return (head(tdm, .n))
}

# main function
processors <- ifelse(IN_DEBUG_MODE, 3, 8)
r_cluster <-  makePSOCKcluster(processors)
registerDoParallel(r_cluster)

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

# merging reports and results dataframes.
reports.merged = merge(reports.data, results.data, by.x="bug_id", by.y="bug_id")

# feature engineering. 
reports.merged <- reports.merged[, c('bug_id', 'long_description', 'long_lived', 'y_hat')]
reports.merged <- reports.merged[complete.cases(reports.merged), ]
  
flog.trace("clean text features")
reports.merged$long_description  <- clean_text(reports.merged$long_description)

# filtering out long-lived correct predicted
flog.trace("clean corpus")
reports.merged         <- subset(reports.merged, long_lived=='Y') 
predicted.corrected    <- make_tdm(subset(reports.merged, y_hat=='Y', select=c(bug_id, long_description)), 100)
predicted.incorrected  <- make_tdm(subset(reports.merged, y_hat=='N', select=c(bug_id, long_description)), 100)

set.seed(144)
wordcloud(words=predicted.corrected$word, freq=predicted.corrected$freq, min.freq=0,
          max.words=100, random.order=FALSE, rot.per=0.35,
          colors=brewer.pal(8, "Dark2"))

set.seed(144)
wordcloud(words=predicted.incorrected$word, freq=predicted.incorrected$freq, min.freq=0,
          max.words=100, random.order=FALSE, rot.per=0.35,
          colors=brewer.pal(8, "Dark2"))

# saving model plot to file 
# plot_file_name = sprintf("%s_rq3e2_%s_%s_%s_%s_%s_%s.jpg", timestamp, project.name
#                          , parameter$classifier, parameter$balancing, parameter$feat  ure
#                          , parameter$n_term, parameter$metric.type)
# plot_file_name_path = file.path(DATADIR, plot_file_name)
# jpeg(plot_file_name_path)
# print(plot(fit_model))
# dev.off()
