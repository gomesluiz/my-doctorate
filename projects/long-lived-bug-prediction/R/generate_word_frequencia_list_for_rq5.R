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
timestamp  <- format(Sys.time(), "%Y%m%d")

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
library(reshape2)

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
make_summarized_tdm <- function(.docs, .n=100) {
  corpus  <- clean_corpus(.docs)
  tdm     <- TermDocumentMatrix(corpus, control=list(weighting=weightTfIdf))
  tdm     <- as.matrix(tdm)
  tdm     <- sort(rowSums(tdm), decreasing=TRUE)
  tdm     <- data.frame(word=names(tdm), freq=tdm)
  return (head(tdm, .n))
}

make_detailed_tdm <- function(.docs, .n=100) {
  corpus  <- clean_corpus(.docs)
  tdm     <- TermDocumentMatrix(corpus, control=list(weighting=weightTfIdf))
  flog.trace(">> tdm building done")
  
  tdm.matrix <- as.matrix(tdm)
  tdm.sorted <- sort(rowSums(tdm.matrix), decreasing=TRUE)
  flog.trace(">> tdm ordering done")
  
  tdm.words <- head(data.frame(word=names(tdm.sorted)), .n)
  flog.trace(">> tdm wording done")
  
  tdm.melted   <- melt(tdm.matrix)
  tdm.melted   <- subset(tdm.melted, Terms %in% tdm.words$word)
  flog.trace(">> tdm melting done")
  
  return (tdm.melted)
}

# main function
for (project.name in c('eclipse', 'gcc'))
{
  flog.trace("reading data files of %s project", project.name)
  reports.path <- file.path(DATADIR, sprintf("20190917_%s_bug_report_data.csv", project.name))
  results.path <- file.path(DATADIR
                            , sprintf("20190926143854_rq4e4_%s_tests_balanced_acc.csv"
                                      , project.name
                                      )
                            )

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
  flog.trace("making document term matrix for true positives predicted bugs")
  reports.merged         <- subset(reports.merged, long_lived=='Y')
  predicted.corrected    <- make_detailed_tdm(subset(reports.merged, y_hat=='Y'
                                            , select=c(bug_id, long_description)), 100)
  predicted.corrected$status_prediction <- 'True Positive'
  #ggplot(predicted.corrected, aes(as.factor(Docs), Terms, fill=log(value))) + 
  #  geom_tile()  + 
  #  xlab("Docs") + 
  #  scale_fill_continuous(low="#FEE6CE", high="#E6550D")+
  #  theme(axis.text.x=element_blank(), axis.text.y=element_blank())
  
  flog.trace("making document term matrix for false negatives predicted bugs")
  predicted.uncorrected  <- make_detailed_tdm(subset(reports.merged, y_hat=='N'
                                            , select=c(bug_id, long_description)), 100)
  predicted.uncorrected$status_prediction <- 'False Negative'
  #ggplot(predicted.uncorrected, aes(as.factor(Docs), Terms, fill=log(value))) + 
  #  geom_tile()  + 
  #  xlab("Docs") + 
  #  scale_fill_continuous(low="#FEE6CE", high="#E6550D")+
  #theme(axis.text.x=element_blank(), axis.text.y=element_blank())
  

  flog.trace("recording TDM")
  frequency.list <- rbind(predicted.corrected, predicted.uncorrected)
  frequency.list$project <- project.name
  frequency.path = file.path(DATADIR, sprintf("%s_%s_tdm_detailed.csv", timestamp, project.name))
  write_csv(frequency.list , frequency.path)
}
flog.trace("processing finished")