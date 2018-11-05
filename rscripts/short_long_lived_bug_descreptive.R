if (!require('caret')) install.packages('caret')
if (!require('qdap')) install.packages('qdap')
if (!require('tm')) install.packages('tm')
if (!require('viridisLite')) install.packages('viridisLite')
if (!require('wordcloud')) install.packages('wordcloud')

library(caret)
library(qdap)
library(tm)
library(wordcloud)
library(viridisLite)

source("~/Workspace/issue-crawler/rscripts/lib_tm.R")

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

# implementar este gráfico
# transparentTheme(trans = .9)
# featurePlot(x = iris[, 1:4], 
#             y = iris$Species,
#             plot = "density", 
#             ## Pass in options to xyplot() to 
#             ## make it prettier
#             scales = list(x = list(relation="free"), 
#                           y = list(relation="free")), 
#             adjust = 1.5, 
#             pch = "|", 
#             layout = c(4, 1), 
#             auto.key = list(columns = 3))

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
