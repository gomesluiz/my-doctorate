# days to resolve boxplot 
plot_boxplot <- function(bug_report_raw_data) {
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
}

plot_histogram<- function(bug_report_raw_data) {
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
}

all_data <- read.csv("~/Workspace/issue-crawler/data/eclipse/csv/r1_bug_report_data.csv", stringsAsFactors=FALSE)
all_data$DaysToResolve <- as.numeric(all_data$DaysToResolve)

plot_boxplot(all_data)
plot_histogram(all_data)

filtered_data <- subset(all_data, DaysToResolve >=0 & DaysToResolve <= 365) 
plot_boxplot(filtered_data)
plot_histogram(filtered_data)
