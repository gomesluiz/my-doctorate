rm(list = ls(all = TRUE))

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

registerDoMC(cores = 8)
flog.threshold(TRACE)

path.script  <- "~/Workspace/issue-crawler/rscripts/"
path.results <- paste(path.script, "results/", sep = "")
source(paste(path.script, "lib_tm.R", sep = ""))
source(paste(path.script, "lib_file.R", sep = ""))

evaluation.file <- GetLastEvaluationFile(path.results)
feature    <- c("Description", "Summary", "Description_Summary")
sampling   <- c("bootstrap", "cv52")
model      <- c("knn", "rf", "svmRadial")
threshold       <- c(seq(4, 32, by = 4), seq(64, 512, by = 32))
parameters <- crossing(feature, model, sampling, threshold)
unused.columns  <- c('Bug_Id', 'Is_Long', 'DaysToResolve')


if (is.na(evaluation.file)) {
  evaluation.file = FormatEvaluationFileName(path.results)
  flog.trace("Current Evaluation file: %s", evaluation.file)
  start.parameter  <- 1
} else {
  flog.trace("Last evaluation file generated: %s", evaluation.file)
  all.lines <- read.csv(evaluation.file, header = TRUE, sep = ","
                        , stringsAsFactors = FALSE)
  last.line <- all.lines[nrow(all.lines), ]
  start.parameter <- which(parameters$feature == last.line$Feature
                           & parameters$model == last.line$Model
                           & parameters$sampling == last.line$Resampling
                           & parameters$threshold == last.line$Threshold)

  start.parameter <- start.parameter + 1
  if (is.na(start.parameter) | (start.parameter > nrow(parameters))) {
    evaluation.file  <- FormatEvaluationFileName(path.results)
    start.parameter  <- 1
  }
}

flog.trace("Starting parameter: %d", start.parameter)

all_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv"
                     , stringsAsFactors = FALSE)
all_data$Description_Summary  <- paste(all_data$Description, all_data$Summary
                                       , sep = " ")
all_data$DaysToResolve        <- as.numeric(all_data$DaysToResolve)

flog.trace("Bug report data file: %s", "r1_bug_report_data.csv")
flog.trace("Number of reports: %d", nrow(all_data))
filtered_data   <- all_data %>%
  filter(DaysToResolve >= 0) %>%
  filter(DaysToResolve <= 730)

flog.trace("Number of reports filtered: %d", nrow(filtered_data))

prev_feature = ""
for (i in start.parameter:nrow(parameters)) {
  parameter <- parameters[i,]
  flog.trace("Making document term matrix from <%s> feature", parameter$feature)
  if (parameter$feature != prev_feature) {
    dtm     <-
      make_dtm(filtered_data[, c('Bug_Id', parameter$feature)], 200)
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
    merged_data[index,!(names(merged_data) %in% unused.columns)]
  train_data_classes <-
    as.data.frame(merged_data[index, c('Is_Long')])
  names(train_data_classes) <- c('Is_Long')

  test_data <-
    merged_data[-index,!(names(merged_data) %in% unused.columns)]
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
      N_Terms = 200,
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
  InsertOneEvaluationData(evaluation.file, one.evaluation)

}
flog.trace("End of predicting long lived bug.")
