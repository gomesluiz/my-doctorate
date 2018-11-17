rm(list=ls(all=TRUE))

if (!require('class')) install.packages("class")
if (!require('caret')) install.packages("caret")
if (!require('doMC')) install.packages("doMC")
if (!require('dplyr')) install.packages("dplyr")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require('randomForest')) install.packages('randomForest')
if (!require('tidytext')) install.packages('tidytext')
if (!require('tidyr')) install.packages("tidyr")
if (!require('utils')) install.packages("utils")

library(doMC)
library(futile.logger)
library(caret)
library(class)
library(tidytext)
library(tidyr)
library(utils)

registerDoMC(cores=8)
flog.threshold(TRACE)

source("~/Workspace/issue-crawler/rscripts/lib_tm.R")

get_last_file <- function(folder="."){
  current.folder = getwd()
  setwd(folder)
  files <- list.files(pattern = "\\-long_live_bug-evaluation.csv$")
  files <- files[sort.list(files, decreasing = TRUE)]
  return (files[1])
}

insert_one_evaluation <- function(evaluation.file, one.evaluation) {
  
  all.evaluations <- read.csv(evaluation.file, header = TRUE, sep=",", stringsAsFactors=FALSE)
  all.evaluations <- rbind(all.evaluations , one.evaluation)  
  write.csv( all.evaluations.evaluation
               , file = evaluation.file
               , row.names = FALSE
               , quote = FALSE
               , sep=",")
}

flog.trace("Opening data files from Eclipse,")

evaluation.file <- get_last_file("~/Workspace/issue-crawler/rscripts/results/") 
sampling   <- c("bootstrap", "cv52")
model      <- c("knn", "rf", "svmRadial")
feature    <- c("Description", "Summary", "Description_Summary")
first.threshold  <- seq(4, 32, by=4)
second.threshold <- seq(64, 512, by=32)
threshold       <- c(first.threshold, second.threshold)
parameters <- crossing(feature, model, sampling, threshold)
if (is.na(evaluation.file)){
  evaluation.file  <- paste("~/Workspace/issue-crawler/rscripts/results/", "/", "%s-%s-evaluation.csv", sep = "")  
  evaluation.file  <- sprintf(evaluation.file, format(Sys.time(), "%Y%m%d%H%M%S"), "long_live_bug")
  start.parameter  <- 1
  append.line <- FALSE
} else {
  all.lines <- read.csv(evaluation.file, header = TRUE, sep=",", stringsAsFactors=FALSE)
  last.line <- all.lines[nrow(all.lines), ]
  start.parameter <- which(parameters$feature == last.line$Feature 
                           & parameters$model == last.line$Model 
                           & parameters$sampling == last.line$Resampling 
                           & parameters$threshold == last.line$Threshold)
  
  start.parameter <- start.parameter + 1
  append.line <- TRUE
  if (is.na(start.parameter) | (start.parameter > nrow(parameters))) {
    evaluation.file  <- paste("~/Workspace/issue-crawler/rscripts/results/", "/", "%s-%s-evaluation.csv", sep = "")  
    evaluation.file  <- sprintf(evaluation.file, format(Sys.time(), "%Y%m%d%H%M%S"), "long_live_bug")
    start.parameter  <- 1
    append.line <- FALSE
  }
}

bug_report_raw_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
bug_report_raw_data$DaysToResolve <- as.numeric(bug_report_raw_data$DaysToResolve)

all_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
all_data$Description_Summary  <- paste(all_data$Description, all_data$Summary, sep = " ")
all_data$DaysToResolve        <- as.numeric(all_data$DaysToResolve)

all.evaluations <- NULL
unused_columns <- c('Bug_Id', 'Is_Long', 'DaysToResolve')
filtered_data   <- all_data %>%
  filter(DaysToResolve >= 0) %>%
  filter(DaysToResolve <= 730)

prev_feature = ""
for (i in start.parameter:nrow(parameters)) {
  parameter <- parameters[i,] 
  flog.trace("Making document term matrix from <%s> feature",
             parameter$feature)
  if (parameter$feature != prev_feature) {
    dtm     <-
      make_dtm(filtered_data[, c('Bug_Id', parameter$feature)], 100)
    dtm_df  <-  as.data.frame(tidy(dtm))
    names(dtm_df) <- c("Bug_Id", "Term", "Count")
    dtm_df  <- dtm_df %>% spread(key = Term,
                                 value = Count,
                                 fill = 0)
    merged_data <-
      merge(
        x = filtered_data[, c("Bug_Id", "DaysToResolve")],
        y = dtm_df,
        all.x = TRUE,
        by.x = "Bug_Id",
        by.y = "Bug_Id"
      )
    merged_data <- na.omit(merged_data)
    prev_feature = parameter$feature
  }
  
  merged_data$Is_Long <-
    as.factor(ifelse(merged_data$DaysToResolve <= parameter$threshold, 0, 1))
  
  
  set.seed(1234)
  index <-
    createDataPartition(merged_data$Is_Long, p = 0.75, list = FALSE)
  
  train_data <-
    merged_data[index,!(names(merged_data) %in% unused_columns)]
  train_data_classes <-
    as.data.frame(merged_data[index, c('Is_Long')])
  names(train_data_classes) <- c('Is_Long')
  
  test_data <-
    merged_data[-index,!(names(merged_data) %in% unused_columns)]
  test_data_classes <-
    as.data.frame(merged_data[-index, c('Is_Long')])
  names(test_data_classes) <- c('Is_Long')
  
  
  flog.trace(
    "Predicting long lived bug with %s using threshold %d and sampling %s.",
    parameter$model,
    parameter$threshold,
    parameter$sampling
  )
  
  if (parameter$sampling == "bootstrap") {
    fit_model <-
      train(train_data,
            train_data_classes$Is_Long,
            method = parameter$model)
  } else {
    fit_control <-
      trainControl(method = "repeatedcv",
                   number = 5,
                   repeats = 2)
    fit_model <-
      train(
        train_data,
        train_data_classes$Is_Long,
        method = parameter$model,
        trControl =  fit_control
      )
  }
  
  predictions <- predict(object = fit_model, test_data)
  
  cm <- confusionMatrix(data = predictions,
                        reference = test_data_classes$Is_Long,
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
  
  flog.trace("Evaluating predicting: Balanced Accuracy: %f", balanced_acc)
  
  one.evaluation <-
    data.frame(
      Dataset = "Eclipse",
      Model = substr(parameter$model, 1, 3),
      Resampling = parameter$sampling,
      Threshold = parameter$threshold,
      Train_Size = nrow(train_data),
      Train_Qt_Class_0 = nrow(subset(train_data_classes, Is_Long == 0)),
      Train_Qt_Class_1 = nrow(subset(train_data_classes, Is_Long == 1)),
      Test_Size = nrow(test_data),
      Test_Qt_Class_0 = nrow(subset(test_data_classes, Is_Long == 0)),
      Test_Qt_Class_1 = nrow(subset(test_data_classes, Is_Long == 1)),
      Feature = parameter$feature,
      N_Terms = 100,
      Tp = tp,
      Fp = fp,
      Tn = tn,
      Fn = fn,
      Acc_0 = acc_class_0,
      Acc_1 = acc_class_1,
      Balanced_Acc = balanced_acc,
      Precision = precision,
      Recall = recall,
      Fmeasure = fmeasure
    )
  
  flog.trace("Recording evaluation results on CSV file.")

}
flog.trace("Recording evaluation results on CSV file.")
