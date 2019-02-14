# nohup Rscript ./predict_long_lived_bug.R > output.log 2>&1 &
rm(list = ls(all = TRUE))

if (!require('class')) install.packages("class")
if (!require('caret')) install.packages("caret")
if (!require('doMC')) install.packages("doMC")
if (!require('dplyr')) install.packages("dplyr")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require("FNN")) install.packages("FNN")
if (!require('randomForest')) install.packages('randomForest')
#if (!require('smotefamily')) install.packages('smotefamily')
if (!require('tidytext')) install.packages('tidytext')
if (!require('tidyverse')) install.packages("tidyverse")
if (!require('utils')) install.packages("utils")

library(doMC)
library(futile.logger)
library(FNN)
library(caret)
library(class)
#library(smotefamily)
library(tidytext)
library(tidyverse)
library(utils)

registerDoMC(cores = 4)
flog.threshold(TRACE)

path.script  <- file.path("~","Workspace", "doctorate", "rscripts")
path.results <- file.path(path.script, "results")
print(path.results)

source(file.path(path.script, "lib_tm.R"))
source(file.path(path.script, "lib_file.R"))

evaluation.file <- GetLastEvaluationFile(path.results)
feature    <- c("Description", "Summary", "Description_Summary")
sampling   <- c("bootstrap", "cv52")
classifier      <- c("knn", "rf", "svmRadial")
threshold       <- c(seq(4, 32, by = 4), seq(64, 512, by = 32))
parameters <- crossing(feature, classifier, sampling, threshold)
unused.columns  <- c('Bug_Id', 'IsLongLived', 'DaysToResolve')

if (is.na(evaluation.file)) {
  evaluation.file = FormatEvaluationFileName(path.results)
  flog.trace("Current Evaluation file: %s", evaluation.file)
  start.parameter  <- 1
} else {
  flog.trace("Last evaluation file generated: %s", evaluation.file)
  all.lines <- read_csv(evaluation.file)
  last.line <- all.lines[nrow(all.lines), ]
  start.parameter <- which(parameters$feature == last.line$Feature
                           & parameters$classifier == last.line$Classifier
                           & parameters$sampling == last.line$Resampling
                           & parameters$threshold == last.line$Threshold)

  start.parameter <- start.parameter + 1
  if (is.na(start.parameter) | (start.parameter > nrow(parameters))) {
    evaluation.file  <- FormatEvaluationFileName(path.results)
    flog.trace("New evaluation file generated: %s", evaluation.file)
    start.parameter  <- 1
  }
}

flog.trace("Starting with parameter: %d", start.parameter)
stop()
data.file <- file.path("~", "Workspace", "doctorate", "data", "eclipse", "csv", "r1_bug_report_data.csv")
all_data <- read.csv(data.file, stringsAsFactors = FALSE)
all_data$Description_Summary  <- paste(all_data$Description, all_data$Summary , sep = " ")
all_data$DaysToResolve        <- as.numeric(all_data$DaysToResolve)

flog.trace("Bug report data file: %s", data.file)
flog.trace("Number of reports in data file: %d", nrow(all_data))

filtered_data   <- all_data %>%
  filter(DaysToResolve >= 0) %>%
  filter(DaysToResolve <= 730)

flog.trace("Number of reports data file after filtering: %d", nrow(filtered_data))

prev_feature = ""
for (i in start.parameter:nrow(parameters)) {
  parameter <- parameters[i,]
  if (parameter$feature != prev_feature) {
    flog.trace("Making document term matrix from <%s> feature", parameter$feature)
    dtm     <- make_dtm(filtered_data[, c('Bug_Id', parameter$feature)], 200)
    dtm_df  <-  as.data.frame(tidy(dtm))
    names(dtm_df) <- c("Bug_Id", "Term", "Count")
    dtm_df  <- dtm_df %>% spread(key = Term, value = Count, fill = 0)
    merged_data <-
      merge(
        x = filtered_data[, c("Bug_Id", "DaysToResolve")],
        y = dtm_df,
        all.x = TRUE,
        by.x = "Bug_Id",
        by.y = "Bug_Id"
      )
    prev_feature = parameter$feature
    merged_data <- na.omit(merged_data)
  }

  set.seed(9560)
  merged_data$Class <- as.factor(ifelse(merged_data$DaysToResolve <= parameter$threshold, 0, 1))
  balanced.data <- downSample(x = merged_data[3:ncol(merged_data)-1], y = merged_data$Class)

  index <- createDataPartition(balanced.data$Class, p = 0.75, list = FALSE)

  last.column  <- ncol(balanced.data)

  X_train <- balanced.data[index, -last.column ]
  X_test  <- balanced.data[-index, -last.column]

  y_train <- balanced.data[index, last.column]
  y_test  <- balanced.data[-index, last.column]

  flog.trace( "Training long lived bug with %s using threshold %d and sampling %s.",
    parameter$classifier,
    parameter$threshold,
    parameter$sampling
  )

  if (parameter$sampling == "bootstrap") {
    fit_model <- train(X_train, y_train, method = parameter$classifier)
  } else {
    fit_control <- trainControl(method = "repeatedcv", number = 5, repeats = 2)
    fit_model <- train( X_train, y_train, method = parameter$classifier, trControl =  fit_control )
  }

  flog.trace( "Predicting long lived bug with %s using threshold %d and sampling %s.",
    parameter$classifier,
    parameter$threshold,
    parameter$sampling
  )

  y_hat <- predict(object = fit_model, X_test)

  flog.trace( "Evaluating long lived bug with %s using threshold %d and sampling %s.",
    parameter$classifier,
    parameter$threshold,
    parameter$sampling
  )
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

  flog.trace("Evaluating predicting: Balanced Accuracy: %f", balanced_acc)

  flog.trace("Building evaluation results dataframe.")
  one.evaluation <-
    data.frame(
      dataset = "Eclipse",
      classifier = parameter$classifier,
      resampling = parameter$sampling,
      distribution = "balanced",
      threshold = parameter$threshold,
      train_size = nrow(X_train),
      train_size_class_0 = length(subset(y_train, y_train == 0)),
      train_size_class_1 = length(subset(y_train, y_train == 1)),
      test_size = nrow(X_test),
      test_size_Class_0 = length(subset(y_test, y_test == 0)),
      test_size_Class_1 = length(subset(y_test, y_test == 1)),
      feature = parameter$feature,
      n_Terms = 200,
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
  InsertOneEvaluationData(evaluation.file, one.evaluation)

}
flog.trace("End of predicting long lived bug.")
