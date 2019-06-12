# nohup Rscript ./predict_long_lived_bug.R > output.log 2>&1 &
rm(list = ls(all.names = TRUE))

if (!require('caret')) install.packages("caret", dependencies = c("Depends", "Suggests"))
if (!require("futile.logger")) install.packages("futile.logger", dependencies = TRUE)
if (!require("klaR")) install.packages("klaR", dependencies = TRUE) # naive bayes package.
if (!require('doParallel')) install.packages("doParallel", dependencies = c("Depends", "Suggests"))
if (!require("qdap")) install.packages("qdap", dependencies = TRUE)
if (!require("SnowballC")) install.packages("Snowballc", dependencies = TRUE)
if (!require("tidyverse")) install.packages("tidyverse", dependencies = TRUE)
if (!require('tidytext')) install.packages('tidytext')
if (!require("tm")) install.packages("tm", dependencies = TRUE)

library(caret)
library(futile.logger)
library(qdap)
library(doParallel)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)

format_file_name <- function(path=".", suffix) {
  # Format evaluation files name.
  #
  # Args:
  #   path: place where evaluation files are stored.
  #
  # Returns:
  #   The file name formatted.
  current.folder = getwd()
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
  files <- list.files(pattern = "\\-metrics.csv$")
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

# main function
flog.threshold(TRACE)
flog.trace("Script started...")
r_cluster <- makePSOCKcluster(4)
registerDoParallel(r_cluster)

label             <- "long_label"
fixed.threshold   <- 64
last.feature      <- ""
metrics.suffix     <- "predicting-metrics"

root.path     <- file.path("~","Workspace", "doctorate", "experiments", "long-lived-bug")
scripts.path  <- file.path(root.path, "scripts")
reports.path  <- file.path(root.path, "datasets")
output.path   <- file.path(scripts.path, "output")
flog.trace("Ouput path: %s", output.path)

metrics.file  <- get_last_evaluation_file(output.path)

feature    <- c("short_description", "long_description", "short_long_description")
resampling <- c("bootstrap", "cv52")
classifier <- c("knn", "rf", "svmRadial")
threshold  <- c(seq(4, fixed.threshold, by = 8))
parameters  <- crossing(feature, classifier, resampling, threshold)

reports.file <- file.path(reports.path, "eclipse_bug_reports.csv")
flog.trace("Bug reports file : %s", reports.file)

if (is.na(metrics.file)) {
  metrics.file = format_file_name(output.path, metrics.suffix)
  flog.trace("Current Evaluation file: %s", metrics.file)
  start.parameter  <- 1
} else {
  flog.trace("Last evaluation file generated: %s", metrics.file)
  all.lines <- read_csv(metrics.file)
  last.line <- all.lines[nrow(all.lines), ]
  start.parameter <- which(parameters$feature == last.line$feature
                           & parameters$classifier == last.line$classifier
                           & parameters$resampling == last.line$resampling
                           & parameters$threshold == last.line$threshold)

  start.parameter <- start.parameter + 1
  if (is.na(start.parameter) | (start.parameter > nrow(parameters))) {
    metrics.file  <- format_file_name(output.path, metrics.suffix)
    flog.trace("New evaluation file generated: %s", metrics.file)
    start.parameter  <- 1
  }
}
flog.trace("Starting with parameter: %d", start.parameter)

# cleaning data
reports <- read_csv(reports.file, na = c("", "NA"))
reports <- reports[, c('bug_id', 'short_description', 'long_description', 'days_to_resolve')]
reports <- reports[complete.cases(reports), ]
reports <- reports %>% filter((days_to_resolve) >= 0 & (days_to_resolve <= 730))
reports$short_description <- clean_text(reports$short_description)
reports$long_description  <- clean_text(reports$long_description)
reports$short_long_description <- paste(reports$short_description, reports$long_description, sep=" ")

for (i in start.parameter:nrow(parameters)) {
  parameter = parameters[i, ]

  if (parameter$feature != last.feature) {
    flog.trace("Text mining: extracting 200 terms")
    source <- reports[, c('bug_id', parameters$feature)]
    corpus <- clean_corpus(source)

    dtm  <- tidy(make_dtm(corpus, 200))
    names(dtm) <- c("bug_id", "term", "count")
    term.matrix <- dtm %>% spread(key = term, value = count, fill = 0)

    reports.terms <- merge(
      x = reports[, c('bug_id', 'days_to_resolve')],
      y = term.matrix,
      by.x = 'bug_id',
      by.y = 'bug_id'
    )
    terms.suffix = paste(parameter$feature, "-features", sep = "")
    terms.file  = format_file_name(output.path, terms.suffix)
    write_csv(reports.terms, terms.file)
    last.feature = parameter$feature
  }

  reports.terms$long_label <- as.factor(ifelse(reports.terms$days_to_resolve <= fixed.threshold, 0, 1))

  short_liveds <- subset(reports.terms , days_to_resolve <= parameter$threshold)
  long_liveds  <- subset(reports.terms , long_label == 1)
  all_reports  <- rbind(short_liveds, long_liveds)
# resampling:
# bootstrap: train_control=(method="boot", number=5)
# k-fold cv: train_control=(method="cv", number=5)
# repeat k-fold cv: train_control=(method="repeatedcv", number=5, repeats=2)
# leave one out cv: train_control=(method="LOOCV")
# metric:
# Accuracy and Kappa
# method:
# knn
# svmRadial
# rf

  set.seed(1)
  flog.trace("Predicting: feature[%s], threshold[%s], classifier[%s], resampling[%s]",
             parameter$feature, parameter$threshold, parameter$classifier, parameter$resampling)
  predictors <- names(all_reports)[!(names(all_reports) %in% c("bug_id", "days_to_resolve", label))]

  balanced.dataset <- downSample(x = all_reports[ , predictors]  , y = all_reports[, label], yname=label)
  in_train <- createDataPartition(balanced.dataset[, label], p = 0.75, list = FALSE)

  X_train <- balanced.dataset[in_train, predictors ]
  y_train <- balanced.dataset[in_train, label]

  X_test  <- balanced.dataset[-in_train, predictors]
  y_test  <- balanced.dataset[-in_train, label]

  if (parameter$resampling == "bootstrap") {
    fit_model <- train(x = X_train, y = y_train, method = parameter$classifier)
  } else {
    fit_control <- trainControl(method = "repeatedcv", number = 5, repeats = 2)
    fit_model <- train(x = X_train, y = y_train, method = parameter$classifier, trControl =  fit_control )
  }

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
      distribution = "balanced",
      threshold = parameter$threshold,
      train_size = nrow(X_train),
      train_size_class_0 = length(subset(y_train, y_train == 0)),
      train_size_class_1 = length(subset(y_train, y_train == 1)),
      test_size = nrow(X_test),
      test_size_class_0 = length(subset(y_test, y_test == 0)),
      test_size_class_1 = length(subset(y_test, y_test == 1)),
      feature = parameter$feature,
      n_terms = 200,
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