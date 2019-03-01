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

down_sample <- function(data, label) {
  #
  #
  # Args:
  #
  #
  # Returns:
  #
  set.seed(1234)

  data.class.0 <- data[which(data[, label] == 0), ]
  data.class.1 <- data[which(data[, label] == 1), ]

  size = min(nrow(data.class.0), nrow(data.class.1))

  sample.class.0 <- sample_n(data.class.0, size, replace = FALSE)
  sample.class.1 <- sample_n(data.class.1, size, replace = FALSE)

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
  files <- list.files(pattern = "\\predicting-metrics-manual.csv$")
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

class_label       <- "long_lived"
fixed.threshold   <- c(8, 64)
last.feature      <- ""
metrics.suffix    <- "predicting-metrics-manual"

root.path     <- file.path("~","Workspace", "doctorate", "experiments", "long-lived-bug")
dataset.path  <- file.path(root.path, "notebooks", "datasets")
output.path   <- file.path(root.path, "notebooks", "datasets")
flog.trace("Ouput path: %s", output.path)

metrics.file  <- file.path(output.path, format(Sys.time()
                              , "%Y%m%d%H%M%S_predicting-metrics-manual.csv"))

feature    <- c("short_description", "long_description", "short_long_description")
resampling <- c("bootstrap", "cv52")
classifier <- c("knn", "rf", "svmRadial")
threshold  <- 8
parameters <- crossing(feature, classifier, resampling, threshold)

reports.file <- file.path(dataset.path, "20190207_eclipse_bug_reports.csv")
flog.trace("Bug reports file : %s", reports.file)

# cleaning data
features <- c('bug_id', 'short_description', 'long_description', 'days_to_resolve')
reports <- read_csv(reports.file, na = c("", "NA"))
reports <- reports[, features]
reports <- reports[complete.cases(reports), ]
reports <- reports %>% filter((days_to_resolve) >= 0 & (days_to_resolve <= 730))
reports$short_description <- clean_text(reports$short_description)
reports$long_description  <- clean_text(reports$long_description)
reports$short_long_description <- paste(reports$short_description, reports$long_description, sep=" ")

flog.trace("Text mining: extracting 200 terms")
source <- reports[, c('bug_id', "short_long_description")]
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



for (fixed in c(8, 64))
{
  reports.terms$long_lived <-
    as.factor(ifelse(reports.terms$days_to_resolve <= fixed, 0, 1))

  short_liveds <- subset(reports.terms , days_to_resolve <= threshold)
  long_liveds  <- subset(reports.terms , long_lived == 1)
  all_reports  <- rbind(short_liveds, long_liveds)

  set.seed(1234)
  balanced.dataset <- down_sample(all_reports, class_label)
  predictors <-
    names(balanced.dataset)[!(names(balanced.dataset) %in% c("bug_id", "days_to_resolve", class_label))]
  in_train <-
    createDataPartition(balanced.dataset[, class_label], p = 0.50, list = FALSE)

  X_train <- balanced.dataset[in_train, predictors]
  y_train <- balanced.dataset[in_train, class_label]

  X_test  <- balanced.dataset[-in_train, predictors]
  y_test  <- balanced.dataset[-in_train, class_label]

  fit_control = trainControl(method = "none")


  for (classifier in c("knn", "svmRadial", "rf")) {
    flog.trace(
      "Evaluating: Classifier: [%s], Fix [%f], Mut [%f]",
      classifier,
      fixed,
      threshold
    )

    fit_model <- train(
      x = X_train,
      y = y_train,
      method = classifier,
      trControl = fit_control
    )

    y_hat <- predict(object = fit_model, X_test)

    cm <-
      confusionMatrix(data = y_hat,
                      reference = y_test,
                      mode = "prec_recall")
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

    flog.trace(
      "Evaluating: Classifier: [%s], Bcc [%f], Acc0 [%f], Acc1 [%f]",
      classifier,
      balanced_acc,
      acc_class_0,
      acc_class_1
    )
    one.evaluation <-
      data.frame(
        dataset = "Eclipse",
        classifier = classifier,
        resampling = "none",
        distribution = "mydownsample",
        fixed_threshold = fixed,
        mutable_threshold = threshold,
        train_size = nrow(X_train),
        train_size_class_0 = length(subset(y_train, y_train == 0)),
        train_size_class_1 = length(subset(y_train, y_train == 1)),
        test_size = nrow(X_test),
        test_size_class_0 = length(subset(y_test, y_test == 0)),
        test_size_class_1 = length(subset(y_test, y_test == 1)),
        feature = "long_description",
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
}
flog.trace("End of predicting long lived bug."
)