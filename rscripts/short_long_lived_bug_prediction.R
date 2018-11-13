rm(list=ls(all=TRUE))

if (!require('class')) install.packages("class")
if (!require('caret')) install.packages("caret")
if (!require('doMC')) install.packages("doMC")
if (!require('dplyr')) install.packages("dplyr")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require('randomForest')) install.packages('randomForest')
if (!require('tidytext')) install.packages('tidytext')
if (!require('tidyr')) install.packages("tidyr")

library(doMC)
library(futile.logger)
library(caret)
library(class)
library(tidytext)
library(tidyr)

registerDoMC(cores=8)
flog.threshold(TRACE)

source("~/Workspace/issue-crawler/rscripts/lib_tm.R")

flog.trace("Opening data files from Eclipse,")
evaluation.file <- paste("~/Workspace/issue-crawler/rscripts/results/", "/", "%s-%s-evaluation.csv", sep = "")
bug_report_raw_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
bug_report_raw_data$DaysToResolve <- as.numeric(bug_report_raw_data$DaysToResolve)

all_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
all_data$Description_Summary  <- paste(all_data$Description, all_data$Summary, sep = " ")
all_data$DaysToResolve        <- as.numeric(all_data$DaysToResolve)

samplings   <- c("bootstrap", "cv52")
models      <- c("knn", "rf", "svmRadial")
thresholds  <- seq(4, 512, by=4)
all.evaluations <- NULL
unused_columns <- c('Bug_Id', 'Is_Long', 'DaysToResolve')
filtered_data   <- all_data %>%
  filter(DaysToResolve >= 0) %>%
  filter(DaysToResolve <= 730)

for (feature in c("Description", "Summary", "Description_Summary")) {
  
  flog.trace("Making document term matrix from <%s> feature", feature)
  dtm     <-  make_dtm(filtered_data[, c('Bug_Id', feature)], 200)
  dtm_df  <-  as.data.frame(tidy(dtm))
  names(dtm_df) <- c("Bug_Id", "Term", "Count")
  dtm_df  <- dtm_df %>% spread(key = Term, value = Count, fill = 0)
  
  merged_data <-
    merge(
      x = filtered_data[, c("Bug_Id", "DaysToResolve")]
      ,
      y = dtm_df,
      all.x = TRUE,
      by.x = "Bug_Id",
      by.y = "Bug_Id"
    )
  merged_data <- na.omit(merged_data)
  
  for (model in models) {
    
    for (threshold in thresholds) {
      merged_data$Is_Long <- as.factor(ifelse(merged_data$DaysToResolve <= threshold, 0, 1))
      
      
      set.seed(1234)
      index <-
        createDataPartition(merged_data$Is_Long, p = 0.75, list = FALSE)
      
      train_data <-
        merged_data[index, !(names(merged_data) %in% unused_columns)]
      train_data_classes <-
        as.data.frame(merged_data[index, c('Is_Long')])
      names(train_data_classes) <- c('Is_Long')
      
      test_data <-
        merged_data[-index, !(names(merged_data) %in% unused_columns)]
      test_data_classes <-
        as.data.frame(merged_data[-index, c('Is_Long')])
      names(test_data_classes) <- c('Is_Long')
      
      for (sampling in samplings) {
        flog.trace("Predicting long lived bug with %s using threshold %d and sampling %s.",
                   model,
                   threshold,
                   sampling)
        
        if (sampling == "bootstrap") {
          fit_model <-
            train(train_data,
                  train_data_classes$Is_Long,
                  method = model)
        } else {
          fit_control <-
            trainControl(method = "repeatedcv",
                         number = 5,
                         repeats = 2)
          fit_model <-
            train(train_data,
                  train_data_classes$Is_Long,
                  method = model,
                  trControl =  fit_control)  
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
            Model = substr(model, 1, 3),
            Resampling = "cv 5x2",
            Threshold = threshold,
            Train_Size = nrow(train_data),
            Train_Qt_Class_0 = nrow(subset(train_data_classes, Is_Long == 0)),
            Train_Qt_Class_1 = nrow(subset(train_data_classes, Is_Long == 1)),
            Test_Size = nrow(test_data),
            Test_Qt_Class_0 = nrow(subset(test_data_classes, Is_Long == 0)),
            Test_Qt_Class_1 = nrow(subset(test_data_classes, Is_Long == 1)),
            Feature = feature,
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
        
        if (is.null(all.evaluations)) {
          all.evaluations <- one.evaluation
        } else {
          all.evaluations <- rbind(all.evaluations , one.evaluation)
        }
      }
    }
  }
}
flog.trace("Recording evaluation results on CSV file.")
write.csv(all.evaluations, file = sprintf(evaluation.file
            , format(Sys.time(), "%Y%m%d%H%M%S"), "long_live_bug")
            , row.names = FALSE, quote = FALSE)
