# nohup Rscript ./20190210_predict_long_lived_bug.R > predict_long_lived_bug.log 2>&1 &

#' Predict if a bug will be long-lived or not.
#'
#' @author Luiz Alberto (gomes.luiz@gmail.com)
#'

rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)

if (!require('caret')) install.packages("caret", dependencies = c("Depends", "Suggests"))
if (!require("futile.logger")) install.packages("futile.logger", dependencies = TRUE)
if (!require("klaR")) install.packages("klaR", dependencies = TRUE) # naive bayes package.
if (!require('doParallel')) install.packages("doParallel", dependencies = c("Depends", "Suggests"))
if (!require("qdap")) install.packages("qdap", dependencies = TRUE)
if (!require("SnowballC")) install.packages("Snowballc", dependencies = TRUE)
if (!require("tidyverse")) install.packages("tidyverse", dependencies = TRUE)
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm", dependencies = TRUE)
if (!require('smotefamily')) install.packages('smotefamily', dependencies = TRUE)

library(caret)
library(futile.logger)
library(qdap)
library(doParallel)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)

# resampling methods
NONE <- "none"
BOOTSTRAP <- "boot"
CV <- "cv"
LOOCV <- "LOOCV"
LOGCV <- "LGOCV"
REPEATEDCV <- "repeatedcv"

# balancing methods
UNBALANCED    <- "unbalanced"
DOWNSAMPLE    <- "downsample"
SMOTEMETHOD   <- "smote"
CUSTOMMETHOD  <- "custom"

SUFFIX <- "validate-predicting-metrics"

choose_resampling <- function(option) {
  #' Choose the caret resampling method control.
  #'
  #' @param method The method of resampling.
  #'
  #' @return The caret resampling method control.

  if (option == BOOTSTRAP) {
    flog.trace("resampling chose: %s", BOOTSTRAP)
    result <- trainControl(method = option)
  } else if (option == CV) {
    flog.trace("resampling chose: %s", CV)
    result <- trainControl(method = option, number = 5)
  } else if (option == REPEATEDCV) {
    flog.trace("resampling chose: %s", REPEATEDCV)
    result <- trainControl(method = option, number = 5, repeats = 2)
  } else {
    flog.trace("resampling chose: %s", option)
    result <- trainControl(method = option)
  }
  return (result)
}

down_sample <- function(x, class) {
  #' Apply down sampling balacing method over a dataset.
  #'
  #' @param x       The undataset
  #' @param class   The class attribute
  #'
  #' @return A balanced dataset.
  #'
  set.seed(1234)

  class.0 <- x[which(x[, class] == 0), ]
  class.1 <- x[which(x[, class] == 1), ]

  size = min(nrow(class.0), nrow(class.1))

  sample.class.0 <- sample_n(class.0, size, replace = FALSE)
  sample.class.1 <- sample_n(class.1, size, replace = FALSE)

  result <- rbind(sample.class.0, sample.class.1)

  return(result)
}

format_file_name <- function(path=".", suffix) {
  # Format evaluation files name.
  #
  # Args:
  #   path: place where evaluation files are stored.
  #
  # Returns:
  #   The file name formatted.
  name  <- file.path(path, "%s-%s.csv")
  name  <- sprintf(name, format(Sys.time(), "%Y%m%d%H%M%S"), suffix)
  return(name)
}

get_last_evaluation_file <- function(folder="."){
  # Gets the last evaluation file processed.
  #
  # Args:
  #   folder: place where evaluation files are stored.
  #
  # Returns:
  #   The full name of the last evalution file.
  current.folder = getwd()
  setwd(folder)
  file_pattern <- paste("\\-", SUFFIX, ".csv$", sep="")
  files <- list.files(pattern = file_pattern)
  files <- files[sort.list(files, decreasing = TRUE)]
  setwd(current.folder)

  if (is.na(files[1])) return(NA)

  return(file.path(folder, files[1]))
}

insert_one_evaluation_data <- function(evaluation.file, one.evaluation) {
  # Insert one evaluation data metrics
  #
  # Args:
  #   evaluation.file: name of evaluation file.
  #   one.evaluation : evaluation dataframe.
  #
  # Returns:
  #   nothing.
  #
  if (file.exists(evaluation.file)) {
    all.evaluations <- read_csv(evaluation.file)
    all.evaluations <- rbind(all.evaluations , one.evaluation)
  } else {
    all.evaluations <- one.evaluation
  }

  write_csv( all.evaluations , evaluation.file)
}

clean_text <- function(text){
  # Clean a text replacing abbreviations, contractions and symbols. Furthermore,
  # this function, converts the text to lower case.
  #
  # Args:
  #   text: text to be cleanned.
  #
  # Returns:
  #   The text cleanned.
  text <- replace_abbreviation(text, ignore.case = TRUE)
  text <- replace_contraction(text, ignore.case = TRUE)
  text <- replace_symbol(text)
  text <- tolower(text)
  return(text)
}

clean_corpus <- function(source) {
  # Clean a corpus of documents.
  #
  #
  # Args:
  #   source: a corpus source.
  #
  # Returns:
  #   The corpus cleanned.
  #
  names(source) <- c('doc_id', 'text')
  source <- DataframeSource(source)
  corpus <- VCorpus(source)

  toSpace <- content_transformer(function(x, pattern) {return (gsub(pattern, " ", x))})
  corpus <- tm_map(corpus, toSpace, "/|@|\\|")
  corpus <- tm_map(corpus, toSpace, "[.]")
  corpus <- tm_map(corpus, toSpace, "<.*?>")
  corpus <- tm_map(corpus, toSpace, "-")
  corpus <- tm_map(corpus, toSpace, ":")
  corpus <- tm_map(corpus, toSpace, "'")
  corpus <- tm_map(corpus, toSpace, " -")

  corpus <-  tm_map(corpus, content_transformer(tolower))
  corpus <-  tm_map(corpus, removePunctuation)
  corpus <-  tm_map(corpus, removeNumbers)
  corpus <-  tm_map(corpus, removeWords, c(stopwords("en")))
  corpus <-  tm_map(corpus, stripWhitespace)

  corpus <- tm_map(corpus, stemDocument)
  corpus <- tm_map(corpus, stripWhitespace)
  return(corpus)
}

make_dtm <- function(corpus, n = 100){
  # makes a document term matrix from a corpus.
  #
  #
  # Args:
  #   corpus: The document corpus.
  #   n     : The number of terms of document matrix.
  #
  # Returns:
  #   The document matrix from corpus with n terms.
  dtm           <- DocumentTermMatrix(corpus, control = list(weighting = weightTfIdf))

  freq <- colSums(as.matrix(dtm))
  freq <- order(freq, decreasing = TRUE)

  return(dtm[, freq[1:n]])
}

balance_dataset <- function(x, label, fnc) {
  #
  #
  # Args:
  #
  #
  # Returns:
  #
  keep <- !(names(x) %in% c("bug_id", "days_to_resolve"))

  if (fnc == UNBALANCED) {
    flog.trace("Balancing: %s", UNBALANCED)
    result <- x[, keep]
  } else if (fnc == CUSTOMMETHOD) {
    flog.trace("Balancing: %s", CUSTOMMETHOD)
    result <- down_sample(x[, keep], label)
  } else if (fnc == DOWNSAMPLE) {
    flog.trace("Balancing: %s", DOWNSAMPLE)
    keep <- !(names(x) %in% c("bug_id", "days_to_resolve", label))
    result <- downSample(x[, keep], y = x[, label], yname = label)
  } else if (fnc == SMOTEMETHOD) {
    flog.trace("Balancing: %s", SMOTEMETHOD)
    keep <- !(names(x) %in% c("bug_id", "days_to_resolve", label))
    colnames(x)[colnames(x) == "class"] <- "Class"
    colnames(x)[colnames(x) == "target"] <- "Target"
    result <- SMOTE(x[, keep], as.numeric(x[, label]), K = 3, dup_size = 0)$data
    colnames(result)[colnames(result) == "class"] <- label
    result[, label] = as.factor(as.numeric(result[, label]) - 1)
  } else {
    stop("balance_dataset: balanced function unknown!")
  }
  return(result)
}

get_next_n_parameter <- function(all.lines, parameters)
{
  last.line <- all.lines[nrow(all.lines), ]
  start.parameter <- which(parameters$feature      == last.line$feature
                           & parameters$classifier == last.line$classifier
                           & parameters$resampling == last.line$resampling
                           & parameters$threshold  == last.line$threshold
                           & parameters$n_term     == last.line$n_term
                           & parameters$balancing  == last.line$balancing)

  if (is.na(start.parameter) | (start.parameter > nrow(parameters))) {
    start.parameter  <- 1
  } else {
    start.parameter <- start.parameter + 1
  }
  return(start.parameter)
}
# main function
flog.threshold(TRACE)
flog.trace("Script started...")
r_cluster <- makePSOCKcluster(4)
registerDoParallel(r_cluster)

class_label       <- "long_lived"
fixed.threshold   <- 64
last.feature      <- ""


root.path     <- file.path("~","Workspace", "doctorate", "experiments", "long-lived-bug")
dataset.path  <- file.path(root.path, "notebooks", "datasets")
output.path   <- file.path(root.path, "notebooks", "datasets")
flog.trace("Ouput path: %s", output.path)

metrics.file  <- get_last_evaluation_file(output.path)

#feature    <- c("short_description", "long_description", "short_long_description")


feature    <- c("short_long_description")
resampling <- c(NONE, BOOTSTRAP)
#classifier <- c("knn", "nb", "nnet", "rf", "svmRadial")
classifier <- c("knn")
#n_term     <- c(100, 200, 300, 400, 500)
n_term     <- c(200)
balancing  <- c(UNBALANCED)
threshold  <- seq(4, fixed.threshold, by = 4)
parameters <- crossing(feature, classifier, resampling, threshold, n_term, balancing)

reports.file <- file.path(dataset.path, "20190207_eclipse_bug_reports.csv")
flog.trace("Bug reports file : %s", reports.file)


if (is.na(metrics.file)) {
  metrics.file = format_file_name(output.path, SUFFIX)
  flog.trace("Current Evaluation file: %s", metrics.file)
  start.parameter  <- 1
} else {
  flog.trace("Last evaluation file generated: %s", metrics.file)
  all.lines <- read_csv(metrics.file)
  start.parameter <- get_next_n_parameter(all.lines, parameters)
  if (start.parameter == 1) {
    metrics.file  <- format_file_name(output.path, metrics.suffix)
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

  reports.terms$long_lived <- as.factor(ifelse(
    reports.terms$days_to_resolve <= fixed.threshold, 0, 1)
  )

  short_liveds <- subset(reports.terms , days_to_resolve <= parameter$threshold)
  long_liveds  <- subset(reports.terms , long_lived == 1)
  all_reports  <- rbind(short_liveds, long_liveds)

  set.seed(1234)
  flog.trace("Predicting: feature[%s], threshold[%s], classifier[%s], resampling[%s], balancing[%s]",
             parameter$feature, parameter$threshold, parameter$classifier, parameter$resampling,
             parameter$balancing)

  flog.trace("Balancing dataset")

  dataset = all_reports
  predictors <- !(names(dataset) %in% c(class_label, "bug_id", "days_to_resolve"))

  flog.trace("Partitioning dataset")
  in_train <- createDataPartition(dataset[, class_label], p = 0.75, list = FALSE)

  X_train <- dataset[in_train, predictors ]
  y_train <- dataset[in_train, class_label]

  X_test  <- dataset[-in_train, predictors]
  y_test  <- dataset[-in_train, class_label]

  flog.trace("Training model: ")
  control <- trainControl(method = parameter$resampling)

  fit_model <- train(  x = X_train
                     , y = y_train
                     , method = parameter$classifier
                     , trControl =  control)

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

  flog.trace("Evaluating: Bcc [%f], Acc0 [%f], Acc1 [%f]", balanced_acc, acc_class_0, acc_class_1)
  one.evaluation <-
    data.frame(
      dataset = "Eclipse",
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