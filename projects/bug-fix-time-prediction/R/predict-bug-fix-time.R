
# nohup Rscript ./predict_long_lived_bug.R > predict_long_lived_bug.log 2>&1 &

#' Predict if a bug will be long-lived or not.
#'
#' @author Luiz Alberto (gomes.luiz@gmail.com)
#'
rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)

library(doParallel)
library(futile.logger)

library(qdap)
library(SnowballC)
library(tidyverse)
library(tidytext)
library(tm)

library(caret)            # knn
library(elasticnet)       # elasticnet 
library(earth)            # earth 
library(gbm)              # gbm
library(kernlab)          # svm 
library(MASS)             # rlm  
library(nnet)             # nnet and avNNet
library(pls)              # pls
library(plyr)             # plyr
library(rpart)            # rpart2 
library(RWeka)            # M5 
library(randomForest)     # rf 

BASEDIR <- file.path("~","Workspace", "doctorate")
DATADIR <- file.path(BASEDIR, "datasets")
LIBDIR  <- file.path(BASEDIR,"lib", "R")
PROJDIR <- file.path(BASEDIR, "bug-fix-time-prediction")
SRCDIR  <- file.path(PROJDIR,"R")

source(file.path(LIBDIR, "clean_corpus.R"))
source(file.path(LIBDIR, "clean_text.R"))
source(file.path(LIBDIR, "make_dtm.R"))
source(file.path(LIBDIR, "train_regression_helper.R"))

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

measure_performance <- function(.model, .x, .y){
    library(MLmetrics)
    predicted <- predict(.model, .x)
    mse       <- MSE(predicted, .y)
    mae       <- MAE(predicted, .y)
    rmse      <- RMSE(predicted, .y)
    r2        <- R2_Score(predicted, .y)
    result    <- data.frame(MSE=mse, RMSE=rmse, R2=r2, MAE=mae)
    
    return(result)
}

flog.threshold(TRACE)
flog.trace("[main] Bug Fix Time Prediction Started")
reports_data <- read_reports_file(DATADIR, project_name)

flog.trace("[main] Cleaning dataset")
reports_data <- clean_reports_data(reports_data)

flog.trace("[main] Making document term matrix")
reports_data_dtm <- make_reports_data_dtm(reports_data, 100)

target_label <- 'days_to_resolve'
#condition <- reports_data_dtm$days_to_resolve > 0
#reports_data_dtm$days_to_resolve[condition] <- log(reports_data_dtm$days_to_resolve[condition], base = 10)
predictors   <- !(names(reports_data_dtm) %in% c('bug_id', target_label))

flog.trace("[main] Partitioning data")
set.seed(100)
in_train <- createDataPartition(reports_data_dtm[, target_label], p = 0.75, list = FALSE)

flog.trace("[main] Pre-processing data")
preProc = preProcess(reports_data_dtm[, predictors], method = c(  "zv"
                                                                , "medianImpute"
                                                                , "center"
                                                                , "scale"
                                                                , "pca")
                     )
preProc = predict(preProc, reports_data_dtm[, predictors])
X_train <- preProc[in_train, ]
X_test  <- preProc[-in_train, ]

y_train <- reports_data_dtm[in_train, target_label]
y_test  <- reports_data_dtm[-in_train, target_label]

method = KNN
flog.trace("[main] Training regressor model usig %s method", method)
model <- train_regressor_with(.x = X_train, .y = y_train, .regressor = method)

flog.trace("[main] Testing regressor")
measure <- measure_performance(.model=model, .x=X_test, .y=y_test)
cat(" MAE:", measure$MAE, "\n"
    , "MSE:", measure$MSE, "\n"
    , "RMSE:", measure$RMSE, "\n"
    , "R-squared:", measure$R2)

#xyplot(X_train ~ predict(model), type = c("p", "g"), xlab = "Predicted",  ylab = "Observed")

# Robust Linear Model
#model    <- train(x = X_train, y = y_train, method = "rlm", trControl = control)

# Robust Linear Model with PC A
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