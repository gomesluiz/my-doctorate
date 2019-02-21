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

SUFFIX <- "validate-predicting-metrics"

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

root.path     <- file.path("~","Workspace", "doctorate", "experiments", "long-lived-bug")
dataset.path  <- file.path(root.path, "notebooks", "datasets")
output.path   <- file.path(root.path, "notebooks", "datasets")
flog.trace("Ouput path: %s", output.path)

reports.file <- file.path(dataset.path, "20190207_eclipse_bug_reports.csv")
flog.trace("Bug reports file : %s", reports.file)

# cleaning data
reports <- read_csv(reports.file, na  = c("", "NA"))
reports <- reports[, c('bug_id', 'short_description', 'long_description', 'days_to_resolve')]
reports <- reports[complete.cases(reports), ]
reports <- reports %>% filter((days_to_resolve) >= 0 & (days_to_resolve <= 730))

flog.trace("Clean text: short_long_description feature")
reports$short_long_description <- clean_text(paste(reports$short_description, reports$long_description, sep=" "))

flog.trace("Build Document Term Matrix: %d terms", 200)
source <- reports[, c('bug_id', 'short_long_description')]
corpus <- clean_corpus(source)

dtm  <- tidy(make_dtm(corpus, 200))
names(dtm) <- c("bug_id", "term", "count")
terms.matrix <- dtm %>% spread(key = term, value = count, fill = 0)

reports.matrix <- merge(
    x = reports[, c('bug_id', 'days_to_resolve')],
    y = terms.matrix,
    by.x = 'bug_id',
    by.y = 'bug_id'
)

for (threshold in seq(4, 64, by = 4)) {
  reports.matrix$long_lived <- as.factor(ifelse(
    reports.matrix$days_to_resolve <= 64, 0, 1)
  )

  short.bugs <- subset(reports.matrix , days_to_resolve <= threshold)
  long.bugs  <- subset(reports.matrix , long_lived == 1)
  all.bugs   <- rbind(short.bugs, long.bugs)

  set.seed(1234)
  flog.trace("Predicting: feature[%s], threshold[%s], classifier[%s], resampling[%s], balancing[%s]",
             'short_long_description', threshold, 'knn', 'boot', 'unbalanced')

  predictors <- !(names(all.bugs) %in% c('long_lived', "bug_id", "days_to_resolve"))
  in_train <- createDataPartition(all.bugs[, 'long_lived'], p = 0.75, list = FALSE)

  X_train <- all.bugs[in_train, predictors ]
  y_train <- all.bugs[in_train, 'long_lived']

  X_test  <- all.bugs[-in_train, predictors]
  y_test  <- all.bugs[-in_train, 'long_lived']

  flog.trace("Training model: ")
  fit_model <- train(  x = X_train
                     , y = y_train
                     , method = 'knn'
                     , trControl =  trainControl(method = 'boot'))

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
      classifier = 'knn',
      resampling = 'boot',
      balancing  =  'unbalanced',
      threshold  = threshold,
      fixed_threshold   = 64,
      train_size = nrow(X_train),
      train_size_class_0 = length(subset(y_train, y_train == 0)),
      train_size_class_1 = length(subset(y_train, y_train == 1)),
      test_size = nrow(X_test),
      test_size_class_0 = length(subset(y_test, y_test == 0)),
      test_size_class_1 = length(subset(y_test, y_test == 1)),
      feature = 'short_long_description',
      n_term = 200,
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
  insert_one_evaluation_data('validate_unbalanced_boot_predict_long_lived.csv', one.evaluation)
}
flog.trace("End of predicting long lived bug.")