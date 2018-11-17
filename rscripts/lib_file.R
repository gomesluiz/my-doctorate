FormatEvaluationFileName <- function(path=".") {
  name  <- paste(path, "%s-%s-evaluation.csv", sep = "")
  name  <- sprintf(name, format(Sys.time(), "%Y%m%d%H%M%S"), "long_live_bug")
  return(name)
}

GetLastEvaluationFile <- function(folder="."){
  # Gets the last evaluation file processed.
  #
  # Args:
  #   folder: place where evaluation files are stored.
  #
  # Returns:
  #   The full name of the last evalution file.
  current.folder = getwd()
  setwd(folder)
  files <- list.files(pattern = "\\-long_live_bug-evaluation.csv$")
  files <- files[sort.list(files, decreasing = TRUE)]
  setwd(current.folder)

  if (is.na(files[1])) return(NA)

  return(paste(folder, files[1], sep = ""))
}

InsertOneEvaluationData <- function(evaluation.file, one.evaluation) {
  # Insert one evaluation data metrics
  if (file.exists(evaluation.file)) {
    all.evaluations <- read.csv(evaluation.file, header = TRUE, sep = ",",
                              stringsAsFactors = FALSE)
    all.evaluations <- rbind(all.evaluations , one.evaluation)
  } else {
    all.evaluations <- one.evaluation
  }

  write.csv( all.evaluations
             , file = evaluation.file
             , row.names = FALSE
             , quote = FALSE
             , sep = ",")
}