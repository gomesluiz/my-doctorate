
# nohup Rscript ./predict_long_lived_bug.R > predict_long_lived_bug.log 2>&1 &

#' Predict if a bug will be long-lived or not.
#'
#' @author Luiz Alberto (gomes.luiz@gmail.com)
#'
rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)

library(caret)
library(doParallel)
library(e1071)
library(futile.logger)
library(qdap)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)

BASEDIR <- file.path("~","Workspace", "doctorate")
DATADIR <- file.path(BASEDIR, "datasets")
LIBDIR  <- file.path(BASEDIR,"lib", "R")
PROJDIR <- file.path(BASEDIR, "bug-fix-time-prediction")
SRCDIR  <- file.path(PROJDIR,"R")

source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))
source(file.path(LIBDIR, "make_dtm.R"))

project_name <- "eclipse"

#' Read the bug repors data file into a R dataframe.
#' 
#' @param .datadir     Data file directory.
#' @param .oss_project Open Source Source project name.
#' 
#' @result A bug report R dataframe.
read_reports_file <- function(.datadir, .oss_project) {
  filename <- sprintf("20190309_%s_bug_report_data.csv", .oss_project)
  filename <- file.path(.datadir, filename)
  result   <- read_csv(filename, na  = c("", "NA"))
  flog.trace("[main] Reading bug report file : %s", filename)
  
  return(result)
}

#' Clean bug reports data.
#' 
#' @param .data Data to be cleaned.
#' 
#' @result Data cleaned.
clean_reports_data <- function(.data){
  result  <- .data[, c('bug_id', 'days_to_resolve')]
  result$short_long_description <- paste(.data$short_description,  .data$long_description, sep=" ")

  result <- result[complete.cases(result), ]
  #result <- result %>% filter((days_to_resolve) >= 0 & (days_to_resolve <= 730))
  
  result$short_long_description <- clean_text(result$short_long_description)
  return (result)
}

#' 
#' 
#' 
#' 
#' 
make_reports_data_dtm <- function(.data, .nterms){
  source <- .data[, c('bug_id', 'short_long_description')]
  corpus <- clean_corpus(source)
  dtm    <- tidy(make_dtm(corpus, .nterms))
  names(dtm)    <- c("bug_id", "term", "count")
  dtm   <- dtm %>% spread(key = term, value = count, fill = 0)
  result <- merge(
    x = .data[, c('bug_id', 'days_to_resolve')],
    y = dtm,
    by.x = 'bug_id',
    by.y = 'bug_id'
  )
  
  return(result)
}

flog.threshold(TRACE)
flog.trace("[main] Bug Fix Time Prediction Started")
reports_data <- read_reports_file(DATADIR, project_name)

flog.trace("[main] Cleaning dataset")
reports_data <- clean_reports_data(reports_data)

flog.trace("[main] Making document term matrix")
reports_data_dtm <- make_reports_data_dtm(reports_data, 100)

flog.trace("[main] Predicting bug-fix time")
set.seed(1234)
target_label <- 'days_to_resolve'
condition <- reports_data_dtm$days_to_resolve > 0
reports_data_dtm$days_to_resolve[condition] <- log(reports_data_dtm$days_to_resolve[condition], base = 10)
predictors   <- !(names(reports_data_dtm) %in% c('bug_id', target_label))

flog.trace("[main] Partitioning data")
in_train <- createDataPartition(reports_data_dtm[, target_label], p = 0.75, list = FALSE)

flog.trace("[main] Pre-processing data")
X_train <- reports_data_dtm[in_train, predictors]
X_train_pre_processed <- preProcess(X_train, method=c("range"))
X_train <- predict(X_train_pre_processed, X_train)
y_train <- reports_data_dtm[in_train, target_label]

X_test  <- reports_data_dtm[-in_train, predictors]
X_test_pre_processed  <- preProcess(X_test, method=c("range"))
X_test <- predict(X_test_pre_processed, X_test)
y_test  <- reports_data_dtm[-in_train, target_label]

flog.trace("[main] Training model usig LM method")
control  <- trainControl(method = "cv", number = 10)
model    <- train(x = X_train, y = y_train, method = "lm", trControl = control)
#xyplot(X_train ~ predict(model), type = c("p", "g"), xlab = "Predicted",  ylab = "Observed")

# Robust Linear Model
#model    <- train(x = X_train, y = y_train, method = "rlm", trControl = control)

# Robust Linear Model with PCA
#model    <- train(x = X_train, 
#                  y = y_train, 
#                  method     = "rlm",
#                  preProcess = "pca",
#                  trControl  = control)

# Robust Linear Model with PCA
#model    <- train(x = X_train, 
#                  y = y_train, 
#                  method     = "pls",
#                  tuneLength = 20,
#                  preProcess = c("center", "scale"),
#                  trControl  = control)