if (!require('qdap')) install.packages('qdap')
if (!require('tm')) install.packages('tm')
if (!require('viridisLite')) install.packages('viridisLite')
if (!require('wordcloud')) install.packages('wordcloud')

library(qdap)
library(tm)
library(wordcloud)
library(viridisLite)

# text cleaning function.
clean_text <- function(text){
  text <- replace_abbreviation(text)
  text <- replace_contraction(text)
# text <- replace_number(text)
# text <- replace_ordinal(text)
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
# make dtm
make_dtm <- function(corpus){
  names(corpus) <- c('doc_id', 'text')
  corpus$text   <- clean_text(corpus$text)
  corpus        <- DataframeSource(corpus)
  corpus        <- Corpus(corpus)
  corpus        <- clean_corpus(corpus)
  dtm           <- DocumentTermMatrix(corpus)
  #dtm           <- removeSparseTerms(dtm, sparse = 0.6)
  return(dtm)
}

# days to resolve boxplot 
plot_boxplot <- function(bug_report_raw_data, label) {
  boxplot(bug_report_raw_data$DaysToResolve
          , outline = FALSE
          , horizontal = TRUE
          , main = sprintf("Boxplot for Days to Resolve (%s)", label)
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
}

plot_histogram<- function(bug_report_raw_data, label) {
  hist(bug_report_raw_data$DaysToResolve
       , main = sprintf("Histogram for Days to Resolve (%s)", label)
       , xlab = "Days"
       , las = 1
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
}

all_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv"
                     , stringsAsFactors=FALSE)
all_data$DaysToResolve <- as.numeric(all_data$DaysToResolve)
all_data <- subset(all_data, DaysToResolve >=0 & DaysToResolve <= 730)
short_bug_data <- subset(all_data, DaysToResolve <= 6)
long_bug_data <- subset(all_data, DaysToResolve > 6)

#plot_boxplot(short_bug_data, "Short Lived Bug")
plot_histogram(all_data, "Eclipse")

#plot_boxplot(long_bug_data, "Long Lived Bug")
#plot_histogram(long_bug_data, "Long Lived Bug")

#color <-  c("blue", "orange", "gold", "indianred", "skyblue4","lightblue")

# Term frequency for short lived bugs. 
summary_short_bug_dtm <- make_dtm(short_bug_data[, c('Bug_Id', 'Summary')])
summary_short_bug_m <- as.matrix(summary_short_bug_dtm)
term_frequency <- colSums(summary_short_bug_m)
term_frequency <- sort(term_frequency, decreasing = TRUE)
barplot(term_frequency[c(1:25)], main = "Term Frequency for Short Lived Bug",
        ylab="Frequency", col = "lightblue", las=2)

# Term frequency for long lived bugs. 
summary_long_bug_dtm <- make_dtm(long_bug_data[, c('Bug_Id', 'Summary')])
summary_long_bug_m <- as.matrix(summary_long_bug_dtm)
term_frequency <- colSums(summary_long_bug_m)
term_frequency <- sort(term_frequency, decreasing = TRUE)
barplot(term_frequency[c(1:25)], main = "Term Frequency for Long Lived Bug"
        , ylab="Frequency", col = "chartreuse", las=2)
