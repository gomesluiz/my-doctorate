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
BASEDIR <- file.path("~","Workspace", "doctorate")
LIBDIR  <- file.path(BASEDIR, "lib", "R")
PRJDIR  <- file.path(BASEDIR, "long-lived-bug-prediction")
SRCDIR  <- file.path(PRJDIR, "R")
DATADIR <- file.path(PRJDIR, "datasets")

if (!require('caret')) install.packages("caret")
if (!require('doParallel')) install.packages("doParallel")
if (!require('e1071')) install.packages("e1071")
if (!require("klaR")) install.packages("klaR") # naive bayes package.
if (!require("kernlab")) install.packages("kernlab")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require("qdap")) install.packages("qdap")
if (!require("ranger")) install.packages("ranger")
if (!require("SnowballC")) install.packages("SnowballC")
if (!require('smotefamily')) install.packages('smotefamily')
if (!require("tidyverse")) install.packages("tidyverse")
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm")

library(caret)
library(doParallel)
library(e1071)
library(klaR)
library(kernlab)
library(futile.logger)
library(qdap)
library(ranger)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)

source(file.path(LIBDIR, "balance_dataset.R"))
source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))
source(file.path(LIBDIR, "format_file_name.R"))
source(file.path(LIBDIR, "get_last_evaluation_file.R"))
source(file.path(LIBDIR, "get_next_n_parameter.R"))
source(file.path(LIBDIR, "get_resampling_method.R"))
source(file.path(LIBDIR, "insert_one_evaluation_data.R"))
source(file.path(LIBDIR, "make_dtm.R"))
source(file.path(LIBDIR, "train_helper.R"))
set.seed(144)

# main function
r_cluster <- makePSOCKcluster(3)
registerDoParallel(r_cluster)

timestamp       <- format(Sys.time(), "%Y%m%d%H%M%S")
class_label     <- "long_lived"
fixed.threshold <- 64

#projects   <- c("eclipse", "freedesktop", "gnome", "mozilla", "netbeans", "winehq")

projects   <- c("eclipse")
n_term     <- c(100)
classifier <- c(KNN, NB, RF, SVM)
feature    <- c("short_description", "long_description")
threshold  <- c(365)
balancing  <- c(UNBALANCED, SMOTE)
resampling <- c("LGOCV")
#resampling <- c("repeatedcv")
parameters <- crossing(n_term, classifier, feature, threshold, balancing, resampling,)

flog.threshold(TRACE)
flog.trace("Long live prediction started with Grid Search, and Short, Long and Short+Long Description")
flog.trace("Evaluation metrics ouput path: %s", DATADIR)

for (project.name in projects){
  flog.trace("Current project name : %s", project.name)
  
  metrics.mask  <- sprintf("%s_result_metrics_grided_all_w_features_separated.csv", project.name)
  metrics.file  <- get_last_evaluation_file(DATADIR, metrics.mask)
 
  # get last parameter number and metrics file. 
  if (is.na(metrics.file)) {
    metrics.file = format_file_name(DATADIR, timestamp, metrics.mask)
    flog.trace("Current evaluation file: %s", metrics.file)
    parameter.number  <- 1
  } else {
    flog.trace("Last evaluation file : %s", metrics.file)
    all.lines <- read_csv(metrics.file)
    parameter.number <- get_next_n_parameter(all.lines, parameters)
    if (parameter.number == 1) {
      metrics.file  <- format_file_name(DATADIR, timestamp, metrics.mask)
      flog.trace("New evaluation file: %s", metrics.file)
    }
  }
  
  flog.trace("Current parameter number: %d", parameter.number)

  reports.file <- file.path(DATADIR, sprintf("20190309_%s_bug_report_data.csv", project.name))
  flog.trace("Bug report file name: %s", reports.file)
  
  # cleaning data
  reports <- read_csv(reports.file, na  = c("", "NA"))
  reports <- reports[, c('bug_id', 'short_description', 'long_description', 'days_to_resolve')]
  reports <- reports[complete.cases(reports), ]
  
  flog.trace("Clean text features")
  reports$short_description <- clean_text(reports$short_description)
  reports$long_description  <- clean_text(reports$long_description)
  reports$short_long_description <- paste(reports$short_description, reports$long_description, sep=" ")
  
  last.n_term <- 0
  for (i in parameter.number:nrow(parameters)) {
    parameter = parameters[i, ]
    
    flog.trace("Current parameters: n_terms [%d], classifier [%s] feature [%s], threshold [%s], balancing [%s], resampling [%s]"
             , parameter$n_term
             , parameter$classifier
             , parameter$feature
             , parameter$threshold
             , parameter$balancing
             , parameter$resampling)

    if (parameter$n_term != last.n_term) {
      flog.trace("Text mining: extracting %d terms", parameter$n_term)
  
      source <- reports[, c('bug_id', parameters$feature)]
      corpus <- clean_corpus(source)
      dtm    <- tidy(make_dtm(corpus, parameter$n_term))
      names(dtm)    <- c("bug_id", "term", "count")
      term.matrix   <- dtm %>% spread(key = term, value = count, fill = 0)
      reports.terms <- merge(
        x = reports[, c('bug_id', 'days_to_resolve')],
        y = term.matrix,
        by.x = 'bug_id',
        by.y = 'bug_id'
      )
      
      flog.trace("Text mining: extracted %d terms", ncol(reports.terms) - 2)
      last.n_term  = parameter$n_term 
    }
    
    ## REPENSAR
    reports.terms$long_lived <- as.factor(ifelse(reports.terms$days_to_resolve <= fixed.threshold, "0", "1"))
   
    ## adult_incomes %>%
    ##  mutate(new_workclass = ifelse(worclass=="Federal-goc", 1 , 0))
    ## new_data <- dummyVars("~gender", data = adult_incomes)
    short_liveds <- subset(reports.terms , days_to_resolve <= parameter$threshold)
    long_liveds  <- subset(reports.terms , long_lived == 1)
    all_reports  <- rbind(short_liveds, long_liveds)

    flog.trace("Training model: balancing dataset")
    dataset = balance_dataset(all_reports, class_label, parameter$balancing)
    predictors <- !(names(dataset) %in% c(class_label))

    flog.trace("Training model: partitioning dataset")
    in_train <- createDataPartition(dataset[, class_label], p = 0.75, list = FALSE)

    # normalize dataset between 0 and 1
    X_train <- dataset[in_train, predictors]
    X_train_pre_processed <- preProcess(X_train, method=c("range"))
    X_train <- predict(X_train_pre_processed, X_train)
    y_train <- dataset[in_train, class_label]

    # normalize dataset between 0 and 1
    X_test  <- dataset[-in_train, predictors]
    X_test_pre_processed  <- preProcess(X_test, method=c("range"))
    X_test <- predict(X_test_pre_processed, X_test)
    y_test  <- dataset[-in_train, class_label]

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
    
    #precision <- tp / (tp + fp)
    #recall    <- tp / (tp + fn)
    #fmeasure  <- (2 * recall * precision) / (recall + precision)
    
    
    #acc_class_0   <- tp / (tp + fp)
    #acc_class_1   <- tn / (tn + fn)
    
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
        fixed_threshold   = fixed.threshold,
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
      #stop("exit")
  }
}
flog.trace("End of predicting long lived bug.")
