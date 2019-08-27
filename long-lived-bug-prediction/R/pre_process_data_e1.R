#' @description 
#' Pre-process bug reports data for long-lived prediction.
#'
#' @author: 
#' Luiz Alberto (gomes.luiz@gmail.com)
#'
#' @usage: 
#' $ nohup Rscript ./pre_process_data.R > pre_process_data.log 2>&1 &
#' 

# clean R Studio session.
rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)

# setup project folders.
BASEDIR <- file.path("~","Workspace", "doctorate")
DATADIR <- file.path(BASEDIR, "datasets")
PRJDIR  <- file.path(BASEDIR, "long-lived-bug-prediction")
LIBDIR  <- file.path(BASEDIR, "lib", "R")
SRCDIR  <- file.path(PRJDIR, "R")

#if (!require('caret')) install.packages("caret")
if (!require('doParallel')) install.packages("doParallel")
#if (!require('e1071')) install.packages("e1071")
#if (!require("klaR")) install.packages("klaR") # naive bayes package.
#if (!require("kernlab")) install.packages("kernlab")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require("qdap")) install.packages("qdap")
#if (!require("ranger")) install.packages("ranger")
if (!require("SnowballC")) install.packages("SnowballC")
#if (!require('smotefamily')) install.packages('smotefamily')
if (!require("tidyverse")) install.packages("tidyverse")
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm")

#library(caret)
library(doParallel)
#library(e1071)
#library(klaR)
#library(kernlab)
library(futile.logger)
library(qdap)
#library(ranger)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)

#source(file.path(LIBDIR, "balance_dataset.R"))
source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))
#source(file.path(LIBDIR, "format_file_name.R"))
#source(file.path(LIBDIR, "get_last_evaluation_file.R"))
#source(file.path(LIBDIR, "get_next_n_parameter.R"))
#source(file.path(LIBDIR, "get_resampling_method.R"))
#source(file.path(LIBDIR, "insert_one_evaluation_data.R"))
source(file.path(LIBDIR, "make_dtm.R"))
#source(file.path(LIBDIR, "train_helper.R"))
set.seed(144)

# main function
r_cluster <- makePSOCKcluster(3)
registerDoParallel(r_cluster)

file.prefix  <- "20190409" 
project.name <- c("eclipse")
feature.name <- c("short_description", "long_description")
n.term       <- c(100)

parameters   <- crossing(project.name, feature.name, n.term)

flog.threshold(TRACE)
flog.trace("Started pre-process data")
flog.trace("Output path: %s", DATADIR)

for (i in nrow(parameters)){
  parameter = parameters[i, ]
  flog.trace("Current project name: %s", parameter$project.name)

  report.file <- file.path(
      DATADIR, 
      sprintf("%s_%s_bug_report_data.csv", file.prefix, parameter$project.name)
  )
  
  flog.trace("Reading bug report file name: %s", report.file)
  
  # cleaning data
  report.data <- read_csv(report.file, na  = c("", "NA"))
  report.data <- report.data[, c('bug_id', 'short_description', 'long_description', 'bug_fix_time')]
  report.data <- report.data[complete.cases(report.data), ]
  
  flog.trace("Cleaning text features")
  report.data$short_description <- clean_text(report.data$short_description)
  report.data$long_description  <- clean_text(report.data$long_description)
  
  for (i in parameters) {
    
    flog.trace("Current parameters: feature [%s], #terms [%d]"
             , parameter$feature.name
             , parameter$n.term)

      flog.trace("Extracting: %d terms", parameter$n.term)
  
      source <- report.data[, c('bug_id', parameters$feature.name)]
      corpus <- clean_corpus(source)
      dtm    <- tidy(make_dtm(corpus, parameter$n.term))
      names(dtm)    <- c("bug_id", "term", "count")
      term.matrix   <- dtm %>% spread(key = term, value = count, fill = 0)
      report.dataset <- merge(
        x = report.data[, c('bug_id', 'bug_fix_time')],
        y = term.matrix,
        by.x = 'bug_id',
        by.y = 'bug_id'
      )
      
      flog.trace("Extracted: %d terms", ncol(report.dataset) - 2)
      write.csv(report.dataset, "%s_%s_%s%_%s_bug_report_data_pre_processed.csv"
                , file.prefix
                , parameter$project.name
                , parameter$feature.name
                , parameter$n.term) 
    }
} 