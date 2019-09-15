if (!require(caret))
  install.packages('caret')

createFolds(rnorm(21), k = 5, list=TRUE, returnTrain = TRUE)