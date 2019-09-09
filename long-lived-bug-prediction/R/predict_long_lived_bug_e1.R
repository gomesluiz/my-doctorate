#' @description 
#' Predict if a bug will be long-lived or not using using Eclipse dataset.
#'
#' @author: 
#' Luiz Alberto (gomes.luiz@gmail.com)
#'
#' @usage: 
#' $ nohup Rscript ./predict_long_lived_bug_experiment_1.R > predict_long_lived_bug_experiment_1.log 2>&1 &
#' 

# clean R Studio session.
rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)

# setup project folders.
IN_DEBUG_MODE <- FALSE
BASEDIR <- file.path("~","Workspace", "doctorate")
LIBDIR  <- file.path(BASEDIR, "lib", "R")
PRJDIR  <- file.path(BASEDIR, "long-lived-bug-prediction")
SRCDIR  <- file.path(PRJDIR, "R")
DATADIR <- file.path(PRJDIR, "notebooks", "datasets")

if (!require('caret')) install.packages("caret")
if (!require('doParallel')) install.packages("doParallel")
if (!require('e1071')) install.packages("e1071")
if (!require("klaR")) install.packages("klaR") # naive bayes package.
if (!require("kernlab")) install.packages("kernlab")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require("nnet")) install.packages("nnet")
if (!require("qdap")) install.packages("qdap")
if (!require("randomForest")) install.packages("randomForest")
if (!require("SnowballC")) install.packages("SnowballC")
if (!require('smotefamily')) install.packages('smotefamily')
if (!require("tidyverse")) install.packages("tidyverse")
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm")
if (!require("xgboost")) install.packages("xgboost")

library(caret)
library(dplyr)
library(doParallel)
library(e1071)
library(klaR)
library(kernlab)
library(futile.logger)
library(nnet)
library(qdap)
library(randomForest)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)

source(file.path(LIBDIR, "balance_dataset.R"))
source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))
source(file.path(LIBDIR, "format_file_name.R"))
source(file.path(LIBDIR, "get_last_evaluation_file.R"))
source(file.path(LIBDIR, "get_next_parameter_number.R"))
source(file.path(LIBDIR, "get_resampling_method.R"))
source(file.path(LIBDIR, "insert_one_evaluation_data.R"))
source(file.path(LIBDIR, "make_dtm.R"))
source(file.path(LIBDIR, "train_helper.R"))

# main function
r_cluster <- makePSOCKcluster(8)
registerDoParallel(r_cluster)

timestamp       <- format(Sys.time(), "%Y%m%d%H%M%S")
class_label     <- "long_lived"

#projects   <- c("eclipse", "freedesktop", "gnome", "mozilla", "netbeans", "winehq")

projects   <- c("eclipse")
n_term     <- c(100)
classifier <- c(KNN, NB, RF, SVM, NNET, XB)
feature    <- c("short_description", "long_description")
threshold  <- c(365)
balancing  <- c(UNBALANCED, SMOTEMETHOD)
resampling <- c("repeatedcv")
parameters <- crossing(n_term, classifier, feature, threshold, balancing, resampling)

#' @description 
#' Convert a report dataset to document term matrix using the feature parameter.
#' 
#' @author 
#' Luiz Alberto (gomes.luiz@gmail.com)
#' 
#' @param .dataset a bug report dataset
#' @param .feature a textual feature
#' @param .nterms  a number of matrix terms 
#' 
convert_dataset_to_term_matrix <- function(.dataset, .feature, .nterms){
  source <- .dataset[, c('bug_id', .feature)]
  corpus <- clean_corpus(source)
  dtm    <- tidy(make_dtm(corpus, .nterms))
  names(dtm)      <- c("bug_id", "term", "count")
  term.matrix     <- dtm %>% spread(key = term, value = count, fill = 0)
  result.dataset  <- merge(
    x = .dataset[, c('bug_id', 'bug_fix_time')],
    y = term.matrix,
    by.x = 'bug_id',
    by.y = 'bug_id'
  )
  # replace the SMOTE reserved words.
  colnames(result.dataset)[colnames(result.dataset) == "class"]  <- "Class"
  colnames(result.dataset)[colnames(result.dataset) == "target"] <- "Target"
  
  return (result.dataset)
}

flog.threshold(TRACE)
flog.trace("Long live prediction Research Question 3 - Experiment 1")
flog.trace("Evaluation metrics ouput path: %s", DATADIR)

for (project.name in projects){
  flog.trace("Current project name : %s", project.name)
  
  parameter.number  <- 1
  metrics.mask      <- sprintf("rq3e1_%s_predict_long_lived_metrics.csv", project.name)
  metrics.file      <- get_last_evaluation_file(DATADIR, metrics.mask)
  
  # get last parameter number and metrics file. 
  if (!is.na(metrics.file)) {
    all.metrics      <- read_csv(metrics.file)
    next.parameter   <- get_next_parameter_number(all.metrics, parameters)
    # There are parameters to be processed.
    if (next.parameter != -1) {
       parameter.number = next.parameter
    }
  }
 
  # A new metric file have to be generated. 
  if (parameter.number == 1) {
    metrics.file <- format_file_name(DATADIR, timestamp, metrics.mask)
    flog.trace("New Evaluation file: %s", metrics.file)
  } else {
    flog.trace("Current Evaluation file: %s", metrics.file)
  }
  
  flog.trace("Starting in parameter number: %d", parameter.number)

  reports.file <- file.path(DATADIR, sprintf("20190830_%s_bug_report_data_small.csv", project.name))
  flog.trace("Bug report file name: %s", reports.file)
  
  reports <- read_csv(reports.file, na  = c("", "NA"))
  if (IN_DEBUG_MODE){
    flog.trace("DEBUG_MODE: Sample bug reports dataset")
    set.seed(144)
    reports <- sample_n(reports, 1000) 
  }

  # feature engineering. 
  reports <- reports[, c('bug_id', 'short_description', 'long_description' , 'bug_fix_time')]
  reports <- reports[complete.cases(reports), ]
  
  flog.trace("Clean text features")
  reports$short_description <- clean_text(reports$short_description)
  reports$long_description  <- clean_text(reports$long_description)
 
  last.feature  <- "" 
  best.accuracy <- 0
  for (i in parameter.number:nrow(parameters)) {
    parameter = parameters[i, ]
    
    flog.trace("Current parameters:\n N.Terms...: [%d]\n Classifier: [%s]\n Feature...: [%s]\n Threshold.: [%s]\n Balancing.: [%s]\n Resampling: [%s]"
             , parameter$n_term , parameter$classifier , parameter$feature
             , parameter$threshold , parameter$balancing , parameter$resampling)

    if (parameter$feature != last.feature){
      flog.trace("Converting dataframe to term matrix")
      flog.trace("Text mining: extracting %d terms from %s", parameter$n_term, parameter$feature)
      reports.dataset <- convert_dataset_to_term_matrix(reports, parameter$feature, parameter$n_term)
      flog.trace("Text mining: extracted %d terms from %s", ncol(reports.dataset) - 2, parameter$feature)
      last.feature = parameter$feature
    }
    
    flog.trace("Partitioning dataset in training and testing")
    set.seed(144)
    reports.dataset$long_lived <- as.factor(ifelse(reports.dataset$bug_fix_time <= parameter$threshold, "N", "Y"))
    in_train <- createDataPartition(reports.dataset$long_lived, p = 0.75, list = FALSE)
    train.dataset <- reports.dataset[in_train, ]
    test.dataset  <- reports.dataset[-in_train, ]
     
    flog.trace("Balancing training dataset")
    balanced.dataset = balance_dataset(train.dataset , class_label
                                       , c("bug_id", "bug_fix_time")
                                       , parameter$balancing)
    
    names(balanced.dataset)[names(balanced.dataset) == "class"] <- "Class"
    X_train <- subset(balanced.dataset, select=-c(long_lived))
    if (parameter$balancing != SMOTEMETHOD){
      # "center": subtract mean from values.
      # "scale" : divide values by standard deviation.
      # ("center", "scale"): combining the scale and center transforms will 
      # standarize your data. Attributes will have a mean value of 0 and standard
      # deviation of 1.
      # "range" : normalize values. Data values can be scaled in the range of [0, 1]
      # which is called normalization.
      flog.trace("Normalizing X_train")
      X_train_pre_processed <- preProcess(X_train, method=c("range"))
      X_train <- predict(X_train_pre_processed, X_train)
    }
    
    y_train <- balanced.dataset[, class_label]
    X_test  <- subset(test.dataset, select=-c(bug_id, bug_fix_time, long_lived))
    if (parameter$balancing != SMOTEMETHOD){
      flog.trace("Normalizing X_test")
      X_test_pre_processed  <- preProcess(X_test, method=c("range"))
      X_test <- predict(X_test_pre_processed, X_test)
    }
    y_test  <- test.dataset[, class_label]

    flog.trace("Training model ")
    fit_control <- get_resampling_method(parameter$resampling)
    # fit_control <- trainControl(method = "repeatedcv", repeats = 5, classProbs = TRUE, 
    #                             summaryFunction = twoClassSummary,
    #                             search = "grid")
    set.seed(144)
    fit_model   <- train_with (.x=X_train, 
                               .y=y_train, 
                               .classifier=parameter$classifier,
                               .control=fit_control)
    
    flog.trace("Testing model ")
    y_hat <- predict(object = fit_model, X_test)

    flog.trace("Calculating evaluating metrics")
    cm <- confusionMatrix(data = y_hat, reference = y_test, positive = "Y")
    tn <- cm$table[1, 1]
    fn <- cm$table[1, 2]
    tp <- cm$table[2, 2]
    fp <- cm$table[2, 1]
    
    prediction_sensitivity   <- sensitivity(data = y_hat, reference = y_test, positive = "Y")
    prediction_specificity   <- sensitivity(data = y_hat, reference = y_test, positive = "N")
    prediction_precision     <- precision(data = y_hat, reference = y_test)
    prediction_recall        <- recall(data = y_hat, reference = y_test)
    prediction_fmeasure      <- F_meas(data = y_hat, reference = y_test)
    prediction_balanced_acc  <- (prediction_sensitivity + prediction_specificity) / 2
    manual_balanced_acc <- (ifelse((tp+fp) == 0, 0, tp/(tp+fp)) + ifelse((tn+fn) == 0, 0, tn/(tn+fn))) / 2  
    
    if (prediction_balanced_acc > best.accuracy){
      test.result = cbind(test.dataset[, c("bug_id", "bug_fix_time", "long_lived")], y_hat)
      write_csv( test.result , file.path(DATADIR, sprintf("%s_rq3e1_%s_test_results.csv", timestamp, project.name)))
      best.accuracy = prediction_balanced_acc
    }
    
    flog.trace("Evaluating model: bcc [%f], sensitivity [%f], specificity [%f]"
               , prediction_balanced_acc, prediction_sensitivity, prediction_specificity)
    one.evaluation <-
      data.frame(
        dataset = project.name,
        n_term = parameter$n_term,
        classifier = parameter$classifier,
        feature = parameter$feature,
        threshold  = parameter$threshold,
        balancing  = parameter$balancing,
        resampling = parameter$resampling,
        train_size = nrow(X_train),
        train_size_class_0 = length(subset(y_train, y_train == "N")),
        train_size_class_1 = length(subset(y_train, y_train == "Y")),
        test_size = nrow(X_test),
        test_size_class_0 = length(subset(y_test, y_test == "N")),
        test_size_class_1 = length(subset(y_test, y_test == "Y")),
        tp = tp,
        fp = fp,
        tn = tn,
        fn = fn,
        sensitivity = prediction_sensitivity,
        specificity = prediction_specificity,
        balanced_acc = prediction_balanced_acc,
        manual_balanced_acc = manual_balanced_acc,
        precision = prediction_precision,
        recall = prediction_recall,
        fmeasure = prediction_fmeasure
      )
      flog.trace("Recording evaluation results on CSV file.")
      insert_one_evaluation_data(metrics.file, one.evaluation)
      flog.trace("Evaluation results recorded on CSV file.")
  }
}
