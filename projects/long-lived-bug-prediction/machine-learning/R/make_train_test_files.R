library(caret)
library(futile.logger)
library(hash)
library(tidyverse)

# clean R Studio session.
rm(list = ls(all.names = TRUE))
options(readr.num_columns = 0)
timestamp       <- format(Sys.time(), "%Y%m%d%H%M%S")

# setup project folders.
DEFAULT_SEED    <- 144
BASEDIR <- file.path("~","Workspace", "doctorate", "projects")
LIBDIR  <- file.path(BASEDIR, "lib", "R")
PRJDIR  <- file.path(BASEDIR, "long-lived-bug-prediction", "machine-learning")
SRCDIR  <- file.path(PRJDIR, "R")
DATADIR <- file.path(PRJDIR, "source", "datasets")

# setup experimental parameters.
projects    <- c("freedesktop", "gcc", "gnome", "mozilla", "winehq")
feature     <- c("long_description")

thresholds  <- hash() 
thresholds['freedesktop'] <- c(28, 173, 162, 365)
thresholds['gcc'] <- c(63, 337, 475, 365)
thresholds['gnome'] <- c(23, 202, 162, 365)
thresholds['mozilla'] <- c(24, 278, 188, 365)
thresholds['winehq'] <- c(220, 491, 798, 365)

flog.threshold(TRACE)
flog.trace("Making Tratn and Test Files")
flog.trace("Evaluation metrics ouput path: %s", DATADIR)

for (project.name in projects){
  flog.trace("Current project name : %s", project.name)
  reports.file <- file.path(DATADIR, sprintf("20190917_%s_bug_report_data.csv", project.name))

  flog.trace("Bug report file name: %s", reports.file)
  reports <- read_csv(reports.file, na  = c("", "NA"))
  reports <- reports[, c('bug_id', 'short_description', 'long_description' , 'bug_fix_time')]
  reports <- reports[complete.cases(reports), ]
  
  for (threshold in thresholds[[project.name]]) {
    # save data to dnn
    set.seed(DEFAULT_SEED)
    reports$class <- as.factor(ifelse(reports$bug_fix_time <= threshold, 0, 1))
    in_train      <- createDataPartition(reports$class, p = 0.75, list = FALSE)
    train.data    <- reports[in_train, ]
    test.data     <- reports[-in_train, ]
    write.csv(train.data, file.path(DATADIR, sprintf("20190917_%s_bug_report_%d_train_data.csv", project.name, threshold)), row.names=F)
    write.csv(test.data,  file.path(DATADIR, sprintf("20190917_%s_bug_report_%d_test_data.csv",  project.name, threshold)), row.names=F)
  }
}
