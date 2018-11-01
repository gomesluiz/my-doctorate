rm(list=ls(all=TRUE))

if (!require('class')) install.packages("class")
if (!require('caret')) install.packages("caret")
if (!require('doMC')) install.packages("doMC")
if (!require('dplyr')) install.packages("dplyr")
if (!require("futile.logger")) install.packages("futile.logger")
if (!require('qdap')) install.packages('qdap')
if (!require('randomForest')) install.packages('randomForest')
if (!require('SnowballC')) install.packages('SnowballC')
if (!require('tm')) install.packages('tm')
if (!require('tidytext')) install.packages('tidytext')
if (!require('tidyr')) install.packages("tidyr")

library(doMC)
library(futile.logger)
library(caret)
library(class)
library(qdap)
library(SnowballC)
library(tm)
library(tidytext)
library(tidyr)

registerDoMC(cores=2)
flog.threshold(TRACE)

# text cleaning function.
clean_text <- function(text){
  text <- replace_abbreviation(text)
  text <- replace_contraction(text)
  text <- replace_symbol(text)
  text <- tolower(text)
  return(text)
}

# corpus cleaning function.
clean_corpus <- function(corpus) {
  toSpace <- content_transformer(function(x, pattern) {return (gsub(pattern, " ", x))})
  corpus <- tm_map(corpus, toSpace, "/|@|\\|")
  corpus <- tm_map(corpus, toSpace, "[.]")
  corpus <- tm_map(corpus, toSpace, "<.*?>")
  corpus <- tm_map(corpus, toSpace, "-")
  corpus <- tm_map(corpus, toSpace, ":")
  corpus <- tm_map(corpus, toSpace, "’")
  corpus <- tm_map(corpus, toSpace, "‘")
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

# make document term matrix
make_dtm <- function(corpus, n = 100){
  names(corpus) <- c('doc_id', 'text')
  corpus$text   <- clean_text(corpus$text)
  
  corpus        <- DataframeSource(corpus)
  corpus        <- Corpus(corpus)
  corpus        <- clean_corpus(corpus)
  
  dtm           <- DocumentTermMatrix(corpus, control = list(weighting = weightTfIdf))
  
  freq <- colSums(as.matrix(dtm))
  freq <- order(freq, decreasing = TRUE)
  
  #dtm           <- removeSparseTerms(dtm, sparse=0.993)
  return(dtm[, freq[1:n]])
}

flog.trace("Opening data files from Eclipse,")
evaluation.file <- paste("~/Workspace/issue-crawler/data/eclipse/csv/", "/", "%s-%s-evaluation.csv", sep = "")
bug_report_raw_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
bug_report_raw_data$DaysToResolve <- as.numeric(bug_report_raw_data$DaysToResolve)

all_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
all_data$Description_Summary  <- paste(all_data$Description, all_data$Summary, sep = " ")
all_data$DaysToResolve        <- as.numeric(all_data$DaysToResolve)

models      <- c("knn", "rf", "svmRadial")
thresholds  <- c(4, 8, 16, 32, 64, 128, 256, 512)
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
      
      flog.trace("Predicting long lived bug with %s using threshold %d.",
                 model,
                 threshold)
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
      
      model_knn <-
        train(train_data, train_data_classes$Is_Long, method = model)
      predictions <- predict(object = model_knn, test_data)
      
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
      balanced_acc <- (acc_class_0 + acc_class_1)/2
        
      flog.trace("Evaluating predicting: Balanced Accuracy: %f", balanced_acc)
      
      one.evaluation <-
        data.frame(
          Dataset = "Eclipse",
          Model = substr(model, 1, 3),
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
flog.trace("Recording evaluation results on CSV file.")
write.csv(all.evaluations, file = sprintf(evaluation.file
            , format(Sys.time(), "%Y%m%d%H%M%S"), "long_live_bug")
            , row.names = FALSE, quote = FALSE)
