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
IN_DEBUG_MODE <- TRUE
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
if (!require("qdap")) install.packages("qdap")
if (!require("randomForest")) install.packages("randomForest")
if (!require("SnowballC")) install.packages("SnowballC")
if (!require('smotefamily')) install.packages('smotefamily')
if (!require("tidyverse")) install.packages("tidyverse")
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm")

library(caret)
library(dplyr)
library(doParallel)
library(e1071)
library(klaR)
library(kernlab)
library(futile.logger)
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
set.seed(144)

# main function
r_cluster <- makePSOCKcluster(3)
registerDoParallel(r_cluster)

timestamp       <- format(Sys.time(), "%Y%m%d")
class_label     <- "long_lived"

#projects   <- c("eclipse", "freedesktop", "gnome", "mozilla", "netbeans", "winehq")

projects   <- c("eclipse")
n_term     <- c(100)
classifier <- c(KNN, NB, RF, SVM)
feature    <- c("short_description", "long_description")
threshold  <- c(365)
balancing  <- c(UNBALANCED, SMOTEMETHOD)
resampling <- c("repeatedcv")
parameters <- crossing(n_term, classifier, feature, threshold, balancing, resampling)

flog.threshold(TRACE)
flog.trace("Long live prediction started with Grid Search, and Short, Long and Short+Long Description")
flog.trace("Evaluation metrics ouput path: %s", DATADIR)

for (project.name in projects){
  flog.trace("Current project name : %s", project.name)
  
  parameter.number  <- 1
  metrics.mask      <- sprintf("%s_predict_long_lived_rq3e1_evaluation_metrics.csv", project.name)
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

  reports.file <- file.path(DATADIR, sprintf("20190824_%s_bug_report_data.csv", project.name))
  flog.trace("Bug report file name: %s", reports.file)
  
  # cleaning data
  reports <- read_csv(reports.file, na  = c("", "NA"))
  if (IN_DEBUG_MODE){
    flog.trace("DEBUG_MODE: Sample bug reports dataset")
    reports <- sample_n(reports, 1000) 
  }
  reports <- reports[, c('bug_id', 'short_description', 'long_description'
                         , 'bug_fix_time')]
  reports <- reports[complete.cases(reports), ]
  
  flog.trace("Clean text features")
  reports$short_description <- clean_text(reports$short_description)
  reports$long_description  <- clean_text(reports$long_description)
 
  last.n_term  <- 0
  last.feature <- ""
  for (i in parameter.number:nrow(parameters)) {
    parameter = parameters[i, ]
    
    flog.trace("Current parameters:\n N.Terms...: [%d]\n Classifier: [%s]\n Feature...: [%s]\n Threshold.: [%s]\n Balancing.: [%s]\n Resampling: [%s]"
             , parameter$n_term , parameter$classifier , parameter$feature
             , parameter$threshold , parameter$balancing , parameter$resampling)

    if ((parameter$n_term != last.n_term) || (parameter$feature != last.feature)){
      flog.trace("Text mining: extracting %d terms from %s", parameter$n_term, parameter$feature)
  
      source <- reports[, c('bug_id', parameters$feature)]
      corpus <- clean_corpus(source)
      dtm    <- tidy(make_dtm(corpus, parameter$n_term))
      names(dtm)      <- c("bug_id", "term", "count")
      term.matrix     <- dtm %>% spread(key = term, value = count, fill = 0)
      reports.dataset <- merge(
        x = reports[, c('bug_id', 'bug_fix_time')],
        y = term.matrix,
        by.x = 'bug_id',
        by.y = 'bug_id'
      )
      
      flog.trace("Text mining: extracted %d terms from %s", ncol(reports.dataset) - 2, parameter$feature)
      last.n_term  = parameter$n_term
      last.feature = parameter$feature
    }
    
    ## REPENSAR
    reports.dataset$long_lived <- as.factor(ifelse(reports.dataset$bug_fix_time <= parameter$threshold, 0, 1))
   
    flog.trace("Balancing dataset")
    balanced.dataset = balance_dataset(reports.dataset, class_label, c("bug_id", "bug_fix_time"), parameter$balancing)
    predictors <- !(names(balanced.dataset) %in% c(class_label))

    flog.trace("Partitioning dataset")
    in_train <- createDataPartition(balanced.dataset[, class_label], p = 0.75, list = FALSE)

    X_train <- balanced.dataset[in_train, predictors]
    #X_train_pre_processed <- preProcess(X_train, method=c("range"))
    #X_train <- predict(X_train_pre_processed, X_train)
    y_train <- balanced.dataset[in_train, class_label]

    X_test  <- balanced.dataset[-in_train, predictors]
    #X_test_pre_processed  <- preProcess(X_test, method=c("range"))
    #X_test <- predict(X_test_pre_processed, X_test)
    y_test  <- balanced.dataset[-in_train, class_label]

    flog.trace("Training model: ")
    fit_control <- get_resampling_method(parameter$resampling)
    fit_model   <- train_with (.x=X_train, 
                               .y=y_train, 
                               .classifier=parameter$classifier,
                               .control=fit_control)
    
    flog.trace("Testing model: ")
    y_hat <- predict(object = fit_model, X_test)

    cm <- confusionMatrix(data = y_hat, reference = y_test, positive = "1")
    tn <- cm$table[1, 1]
    fn <- cm$table[1, 2]
    
    tp <- cm$table[2, 2]
    fp <- cm$table[2, 1]
    
    prediction_sensitivity   <- sensitivity(data = y_hat, reference = y_test, positive = "1")
    prediction_specificity   <- sensitivity(data = y_hat, reference = y_test, positive = "0")
    prediction_precision     <- precision(data = y_hat, reference = y_test)
    prediction_recall        <- recall(data = y_hat, reference = y_test)
    prediction_fmeasure      <- F_meas(data = y_hat, reference = y_test)
    prediction_balanced_acc  <- (prediction_sensitivity + prediction_specificity) / 2
    manual_balanced_acc <- (tp/(tp+fp) + tn/(tn+fn)) / 2  
    
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
        train_size_class_0 = length(subset(y_train, y_train == "0")),
        train_size_class_1 = length(subset(y_train, y_train == "1")),
        test_size = nrow(X_test),
        test_size_class_0 = length(subset(y_test, y_test == "0")),
        test_size_class_1 = length(subset(y_test, y_test == "1")),
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
      #stop("exit")
  }
}
flog.trace("End of predicting long lived bug.")
