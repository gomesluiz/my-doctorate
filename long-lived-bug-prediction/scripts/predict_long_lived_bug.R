# nohup Rscript ./predict_long_lived_bug.R > predict_long_lived_bug.log 2>&1 &

#' Predict if a bug will be long-lived or not.
#'
#' @author Luiz Alberto (gomes.luiz@gmail.com)
#'

rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)

BASEDIR <- file.path("~","Workspace", "doctorate", "long-lived-bug-prediction")
SRCDIR  <- file.path(BASEDIR,"scripts")
LIBDIR  <- file.path(SRCDIR,"lib")
DATADIR <- file.path(BASEDIR, "notebooks", "datasets")

if (!require('caret')) install.packages("caret", dependencies = c("Depends", "Suggests"))
if (!require('doParallel')) install.packages("doParallel", dependencies = c("Depends", "Suggests"))
if (!require('e1071')) install.packages("e1071", dependencies = c("Depends", "Suggests"))
if (!require("futile.logger")) install.packages("futile.logger", dependencies = TRUE)
if (!require("qdap")) install.packages("qdap", dependencies = TRUE)
if (!require("SnowballC")) install.packages("Snowballc", dependencies = TRUE)
if (!require("tidyverse")) install.packages("tidyverse", dependencies = TRUE)
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm", dependencies = TRUE)
if (!require('smotefamily')) install.packages('smotefamily', dependencies = TRUE)

library(caret)
library(doParallel)
library(e1071)
library(futile.logger)
library(qdap)
library(SnowballC)
library(smotefamily)
library(tidyverse)
library(tidytext)
library(tm)

source(file.path(LIBDIR, "balance_dataset.R"))
source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))
source(file.path(LIBDIR, "do_down_sampling.R"))
source(file.path(LIBDIR, "format_file_name.R"))
source(file.path(LIBDIR, "get_last_evaluation_file.R"))
source(file.path(LIBDIR, "get_next_n_parameter.R"))
source(file.path(LIBDIR, "get_resampling_method.R"))
source(file.path(LIBDIR, "insert_one_evaluation_data.R"))
source(file.path(LIBDIR, "make_dtm.R"))

# main function
r_cluster <- makePSOCKcluster(4)
registerDoParallel(r_cluster)

timestamp       <- format(Sys.time(), "%Y%m%d%H%M%S")
oss.projects    <- c("eclipse", "freedesktop", "gnome", "kernel", "mozilla", "netbeans", "winehq")
dataset.name    <- "eclipse"
metrics.mask    <- sprintf("%s_result_metrics.csv", dataset.name)
models.mask     <- sprintf("%s_final_model.rds", dataset.name)
class_label     <- "long_lived"
fixed.threshold <- 64

metrics.file  <- get_last_evaluation_file(DATADIR, metrics.mask)

feature    <- c("short_long_description")
resampling <- unlist(resampling_methods)
classifier <- c("knn")
n_term     <- c(200)
balancing  <- c(UNBALANCED, MANUALMETHOD, DOWNSAMPLE, SMOTEMETHOD)
threshold  <- seq(4, fixed.threshold, by = 4)
parameters <- crossing(feature, classifier, resampling, threshold, n_term, balancing)

reports.file <- file.path(DATADIR, sprintf("20190309_%s_bug_report_data.csv", dataset.name))

flog.threshold(TRACE)
flog.trace("Script started...")
flog.trace("Ouput path: %s", DATADIR)
flog.trace("Bug reports file : %s", reports.file)

if (is.na(metrics.file)) {
  metrics.file = format_file_name(DATADIR, timestamp, metrics.mask)
  flog.trace("Current Evaluation file: %s", metrics.file)
  start.parameter  <- 1
} else {
  flog.trace("Last evaluation file generated: %s", metrics.file)
  all.lines <- read_csv(metrics.file)
  start.parameter <- get_next_n_parameter(all.lines, parameters)
  if (start.parameter == 1) {
    metrics.file  <- format_file_name(DATADIR, timestamp, metrics.mask)
    flog.trace("New evaluation file generated: %s", metrics.file)
  }
}
flog.trace("Starting with parameter: %d", start.parameter)

# cleaning data
reports <- read_csv(reports.file, na  = c("", "NA"))
reports <- reports[, c('bug_id', 'short_description', 'long_description', 'days_to_resolve')]
reports <- reports[complete.cases(reports), ]
reports <- reports %>% filter((days_to_resolve) >= 0 & (days_to_resolve <= 730))

flog.trace("Clean text features")
reports$short_description <- clean_text(reports$short_description)
reports$long_description  <- clean_text(reports$long_description)
reports$short_long_description <- paste(reports$short_description, reports$long_description, sep=" ")

greatest_balanced_acc <- 0
last.feature <- "@"
model.file   <- format_file_name(DATADIR , timestamp , models.mask)

for (i in start.parameter:nrow(parameters)) {
  parameter = parameters[i, ]

  if (parameter$feature != last.feature) {
    flog.trace("Text mining: extracting %d terms", parameter$n_term)
    source <- reports[, c('bug_id', parameters$feature)]
    corpus <- clean_corpus(source)

    dtm  <- tidy(make_dtm(corpus, parameter$n_term))
    names(dtm) <- c("bug_id", "term", "count")
    term.matrix <- dtm %>% spread(key = term, value = count, fill = 0)

    reports.terms <- merge(
      x = reports[, c('bug_id', 'days_to_resolve')],
      y = term.matrix,
      by.x = 'bug_id',
      by.y = 'bug_id'
    )
    last.feature = parameter$feature
  }

  reports.terms$long_lived <- as.factor(ifelse(reports.terms$days_to_resolve <= fixed.threshold, 0, 1))

  short_liveds <- subset(reports.terms , days_to_resolve <= parameter$threshold)
  long_liveds  <- subset(reports.terms , long_lived == 1)
  all_reports  <- rbind(short_liveds, long_liveds)

  set.seed(1234)
  flog.trace("Predicting: feature[%s], threshold[%s], classifier[%s], resampling[%s], balancing[%s]",
             parameter$feature, parameter$threshold, parameter$classifier, parameter$resampling,
             parameter$balancing)

  flog.trace("Balancing dataset")
  dataset = balance_dataset(all_reports, class_label, parameter$balancing)
  predictors <- !(names(dataset) %in% c(class_label))

  flog.trace("Partitioning dataset")
  in_train <- createDataPartition(dataset[, class_label], p = 0.75, list = FALSE)

  X_train <- dataset[in_train, predictors]
  y_train <- dataset[in_train, class_label]

  X_test  <- dataset[-in_train, predictors]
  y_test  <- dataset[-in_train, class_label]

  flog.trace("Training model: ")
  fit_model <- train(  x = X_train
                     , y = y_train
                     , method = parameter$classifier
                     , trControl =  get_resampling_method(parameter$resampling))

  flog.trace("Testing model: ")
  y_hat <- predict(object = fit_model, X_test)

  cm <- confusionMatrix(data = y_hat, reference = y_test, mode = "prec_recall")
  tp <- cm$table[1, 1]
  fp <- cm$table[1, 2]
  tn <- cm$table[2, 1]
  fn <- cm$table[2, 2]

  precision <- tp / (tp + fp)
  recall <- tp / (tp + fn)
  fmeasure <- (2 * recall * precision) / (recall + precision)
  acc_class_0 <- tp / (tp + fp)
  acc_class_1 <- tn / (tn + fn)
  balanced_acc <- (acc_class_0 + acc_class_1) / 2
  
  if (balanced_acc > greatest_balanced_acc){
    saveRDS(fit_model, model.file)
    greatest_balanced_acc <- balanced_acc
  }

  flog.trace("Evaluating: Bcc [%f], Acc0 [%f], Acc1 [%f]", balanced_acc, acc_class_0, acc_class_1)
  one.evaluation <-
    data.frame(
      dataset = dataset.name,
      classifier = parameter$classifier,
      resampling = parameter$resampling,
      balancing  = parameter$balancing,
      threshold  = parameter$threshold,
      fixed_threshold   = fixed.threshold,
      train_size = nrow(X_train),
      train_size_class_0 = length(subset(y_train, y_train == 0)),
      train_size_class_1 = length(subset(y_train, y_train == 1)),
      test_size = nrow(X_test),
      test_size_class_0 = length(subset(y_test, y_test == 0)),
      test_size_class_1 = length(subset(y_test, y_test == 1)),
      feature = parameter$feature,
      n_term = parameter$n_term,
      tp = tp,
      fp = fp,
      tn = tn,
      fn = fn,
      acc_class_0 = acc_class_0,
      acc_class_1 = acc_class_1,
      balanced_acc = balanced_acc,
      precision = precision,
      recall = recall,
      fmeasure = fmeasure
    )

  flog.trace("Recording evaluation results on CSV file.")
  insert_one_evaluation_data(metrics.file, one.evaluation)
}
flog.trace("End of predicting long lived bug.")
