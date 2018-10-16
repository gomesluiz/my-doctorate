if (!require('qdap')) install.packages('qdap')
if (!require('tm')) install.packages('tm')

#if (!require('Weka')) install.packages('Weka')

library(tm)
library(qdap)

# text cleaning function.
clean_text <- function(text){
  text <- replace_abbreviation(text)
  text <- replace_contraction(text)
  text <- replace_number(text)
  text <- replace_ordinal(text)
  text <- replace_symbol(text)
  text <- tolower(text)
  return(text)
}

# corpus cleaning function.
clean_corpus <- function(corpus) {
  corpus <-  tm_map(corpus, removePunctuation)
  corpus <-  tm_map(corpus, stripWhitespace)
  corpus <-  tm_map(corpus, removeNumbers)
  corpus <-  tm_map(corpus, content_transformer(tolower))
  corpus <-  tm_map(corpus, removeWords, c(stopwords("en"), "eclipse"))
  return(corpus)
}

make_tdm <- function(corpus){
  names(corpus) <- c('doc_id', 'text')
  corpus$text   <- clean_text(corpus$text)
  corpus        <- DataframeSource(corpus)
  corpus        <- Corpus(corpus)
  corpus        <- clean_corpus(corpus)
  dtm           <- DocumentTermMatrix(corpus)
  return(dtm)
}
  
# tokenizer <- function(x){
#   NGramTokenizer(x, Weka_control(min = 3, max = 3))
# }

bug_report_raw_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
bug_report_raw_data$DaysToResolve <- as.numeric(bug_report_raw_data$DaysToResolve)

# days to resolve boxplot 
boxplot(bug_report_raw_data$DaysToResolve
        , outline = FALSE
        , horizontal = TRUE
        , main = "Boxplot for Days to Resolve (Eclipse)"
        , xlab = "Days"
        , noch = TRUE
        , varwidth = TRUE)
abline(v = mean(bug_report_raw_data$DaysToResolve),
       col = "royalblue",
       lwd = 2)
abline(v = median(bug_report_raw_data$DaysToResolve),
       col = "red",
       lwd = 2)
legend(x = "topright", # location of legend within plot area
       c("Mean", "Median"),
       col = c("royalblue", "red"),
       lwd = c(2, 2, 2))

# days to resolve histogram 
hist(bug_report_raw_data$DaysToResolve
     , main = "Histogram for Days to Resolve (Eclipse)"
     , xlab = "Days"
#     , xlim = c(0, 365)
     , las = 1
#     , breaks=c(0, seq(6,390, 6))
)
abline(v = mean(bug_report_raw_data$DaysToResolve),
       col = "royalblue",
       lwd = 2)
abline(v = median(bug_report_raw_data$DaysToResolve),
       col = "red",
       lwd = 2)
legend(x = "topright", # location of legend within plot area
       c("Mean", "Median"),
       col = c("royalblue", "red"),
       lwd = c(2, 2, 2))


bug_report_raw_data <- subset(bug_report_raw_data, DaysToResolve >=0 & DaysToResolve <= 365)

# days to resolve boxplot 
boxplot(bug_report_raw_data$DaysToResolve
        , outline = FALSE
        , horizontal = TRUE
        , main = "Boxplot for Days to Resolve (Eclipse)"
        , xlab = "Days (<= 365)"
        , noch = TRUE
        , varwidth = TRUE)
abline(v = mean(bug_report_raw_data$DaysToResolve),
       col = "royalblue",
       lwd = 2)
abline(v = median(bug_report_raw_data$DaysToResolve),
       col = "red",
       lwd = 2)
legend(x = "topright", # location of legend within plot area
       c("Mean", "Median"),
       col = c("royalblue", "red"),
       lwd = c(2, 2, 2))

# days to resolve histogram 
hist(bug_report_raw_data$DaysToResolve
      , main = "Histogram for Days to Resolve (Eclipse)"
      , xlab = "Days (<= 365)"
      , xlim = c(0, 365)
      , las = 1
      , breaks=c(0, seq(6,390, 6))
)
abline(v = mean(bug_report_raw_data$DaysToResolve),
        col = "royalblue",
        lwd = 2)
abline(v = median(bug_report_raw_data$DaysToResolve),
       col = "red",
       lwd = 2)
legend(x = "topright", # location of legend within plot area
       c("Mean", "Median"),
       col = c("royalblue", "red"),
       lwd = c(2, 2, 2))
#summary_dtm     <- make_tdm(bug_report_raw_data[, c('Key', 'Summary')])
#description_dtm <- make_tdm(bug_report_raw_data[, c('Key', 'Description')])


