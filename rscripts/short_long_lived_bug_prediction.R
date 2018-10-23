rm(list=ls(all=TRUE))


if (!require("futile.logger")) install.packages("futile.logger")
if (!require('class')) install.packages("class")
if (!require('caret')) install.packages("caret")
if (!require('qdap')) install.packages('qdap')
if (!require('SnowballC')) install.packages('SnowballC')
if (!require('tm')) install.packages('tm')
if (!require('tidytext')) install.packages('tidytext')
if (!require('tidyr')) install.packages("tidyr")

library(futile.logger)
library(caret)
library(class)
library(qdap)
library(SnowballC)
library(tm)
library(tidytext)
library(tidyr)

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
  corpus <-  tm_map(corpus, removeWords, c(stopwords("en"), "eclipse", "java"))
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

flog.trace("1. opening data files on %s", format(Sys.time(), "%Y%m%d%H%M%S"))
bug_report_raw_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
bug_report_raw_data$DaysToResolve <- as.numeric(bug_report_raw_data$DaysToResolve)

all_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
all_data$DaysToResolve <- as.numeric(all_data$DaysToResolve)
all_data <- subset(all_data, DaysToResolve >=0 & DaysToResolve <= 730)
all_data$Is_Long <- as.factor(ifelse(all_data$DaysToResolve <= 4, 0, 1))

evaluation.file <- paste("~/Workspace/issue-crawler/data/eclipse/csv/", "/", "%s-%s-evaluation.csv", sep = "")

flog.trace("2. making document term matrix")
summary_dtm <- make_dtm(all_data[, c('Bug_Id', 'Summary')], 200)
summary_dtm_df <- as.data.frame(tidy(summary_dtm))
names(summary_dtm_df) <- c("Bug_Id", "Term", "Count")
summary_dtm_df <- summary_dtm_df %>% spread(key=Term, value=Count, fill=0)

all_data <- merge(x=all_data[, c("Bug_Id", "Is_Long")], y=summary_dtm_df, all.x=TRUE, by.x="Bug_Id", by.y="Bug_Id")
all_data <- na.omit(all_data)
all.evaluations <- NULL

flog.trace("3. predicting long lived bug.")
set.seed(1234)
index <- createDataPartition(all_data$Is_Long, p=0.75, list=FALSE)
train_data <- all_data[index, !(names(all_data) %in% c('Bug_Id', 'Is_Long'))]
train_data_classes <- all_data[index, c('Is_Long')]
test_data <- all_data[-index, !(names(all_data) %in% c('Bug_Id', 'Is_Long'))]
test_data_classes  <- all_data[-index, c('Is_Long')]

train_control <- trainControl(method="repeatedcv", number=10, repeats=3)


model_knn <- train(train_data, train_data_classes, method = 'knn')
predictions <- predict(object=model_knn, test_data)

flog.trace("4. evaluating prediction.")
models <- c("knn")
thresholds <- c(4) 

for (model in models) {
  for (threshold in thresholds) {
    cm <- confusionMatrix(data = predictions,
                          reference = test_data_classes,
                          mode = "prec_recall")
    tp <- cm$table[1, 1]
    fp <- cm$table[1, 2]
    tn <- cm$table[2, 1]
    fn <- cm$table[2, 2]
    
    precision <- tp / (tp + fp)
    recall <- tp / (tp + fn)
    fmeasure <- (2 * recall * precision) / (recall + precision)
    
    one.evaluation <-
      data.frame(
        Model = model,
        Threshold = threshold,
        Precision = precision,
        Recall = recall,
        Fmeasure = fmeasure
      )
    
    if (is.null(all.evaluations)) {
      all.evaluations <- one.evaluation
    } else {
      all.evalutations <- rbind(all.evalutations, one.evaluation)
    }
  }
}
flog.trace("5. recording evaluation results.")
write.csv(all.evaluations, file = sprintf(evaluation.file
            , format(Sys.time(), "%Y%m%d%H%M%S"), "long_live_bug")
            , row.names = FALSE, quote = FALSE)
