rm(list = ls(all = TRUE))

if (!require('class')) install.packages("class")
if (!require('caret')) install.packages("caret")
if (!require('doMC')) install.packages("doMC")
if (!require('dplyr')) install.packages("dplyr")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require('randomForest')) install.packages('randomForest')
if (!require('smotefamily')) install.packages('smotefamily')
if (!require('tidytext')) install.packages('tidytext')
if (!require('tidyr')) install.packages("tidyr")
if (!require('utils')) install.packages("utils")

library(doMC)
library(futile.logger)
library(caret)
library(class)
library(smotefamily)
library(tidytext)
library(tidyr)
library(utils)

registerDoMC(cores = 8)
flog.threshold(TRACE)

path.script  <- file.path("~","Workspace", "issue-crawler", "rscripts")
path.results <- file.path(path.script, "results")
print(path.results)

source(file.path(path.script, "lib_tm.R"))
source(file.path(path.script, "lib_file.R"))

evaluation.file <- GetLastEvaluationFile(path.results)
feature    <- c("Description", "Summary", "Description_Summary")
sampling   <- c("bootstrap", "cv52")
model      <- c("knn", "rf", "svmRadial")
threshold       <- c(seq(4, 32, by = 4), seq(64, 512, by = 32))
parameters <- crossing(feature, model, sampling, threshold)
unused.columns  <- c('Bug_Id', 'IsLongLived', 'DaysToResolve')


if (is.na(evaluation.file)) {
  evaluation.file = FormatEvaluationFileName(path.results)
  flog.trace("Current Evaluation file: %s", evaluation.file)
  start.parameter  <- 1
} else {
  flog.trace("Last evaluation file generated: %s", evaluation.file)
  all.lines <- read.csv(evaluation.file
                        , header = TRUE
                        , sep = ","
                        , stringsAsFactors = FALSE
                        , skipNul = TRUE)
  last.line <- all.lines[nrow(all.lines), ]

  start.parameter <- which(parameters$feature == last.line$Feature
                           & parameters$model == last.line$Model
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

data.file <- file.path("~", "Workspace", "issue-crawler", "data", "eclipse", "csv", "r1_bug_report_data.csv")
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
    merged_data <- na.omit(merged_data)
    prev_feature = parameter$feature
    colnames(merged_data)[colnames(merged_data) == "class"] <- "CLASS"
  }

  merged_data$class <- as.factor(ifelse(merged_data$DaysToResolve <= parameter$threshold, 0, 1))
  balanced.data <- SMOTE(merged_data[, c(3:176, 178:202)], merged_data[, 203], K = 3, dup_size = 0)$data

  set.seed(1234)
  index <- createDataPartition(balanced.data$class, p = 0.75, list = FALSE)

  train_data <- balanced.data[index, 1:199]
  test_data  <- balanced.data[-index, 1:199]

  train_data_classes <- as.data.frame(balanced.data[index, 200])
  test_data_classes <- as.data.frame(balanced.data[-index, 200])

  names(train_data_classes) <- c('class')
  names(test_data_classes) <- c('class')

  flog.trace( "Predicting long lived bug with %s using threshold %d and sampling %s.",
    parameter$model,
    parameter$threshold,
    parameter$sampling
  )

  if (parameter$sampling == "bootstrap") {
    fit_model <- train(train_data, train_data_classes$class, method = parameter$model)
  } else {
    fit_control <- trainControl(method = "repeatedcv", number = 5, repeats = 2)
    fit_model <- train( train_data, train_data_classes$class, method = parameter$model,
        trControl =  fit_control )
  }

  predictions <- predict(object = fit_model, test_data)

  cm <- confusionMatrix(data = predictions, reference = test_data_classes$class,
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
      Model = parameter$model,
      Resampling = parameter$sampling,
      Distribution = "balanced",
      Threshold = parameter$threshold,
      Train_Size = nrow(train_data),
      Train_Qt_Class_0 = nrow(subset(train_data_classes, class == 0)),
      Train_Qt_Class_1 = nrow(subset(train_data_classes, class == 1)),
      Test_Size = nrow(test_data),
      Test_Qt_Class_0 = nrow(subset(test_data_classes, class == 0)),
      Test_Qt_Class_1 = nrow(subset(test_data_classes, class == 1)),
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
