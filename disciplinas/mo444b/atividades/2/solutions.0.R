# ----------------------------------------------------------------------
# Description:
#	  Solutions for activity 1 (MO444)
#
# Version: 1.0
#
# Author:
#		Luiz Alberto, gomes.luiz@gmail.com
#
# History:
#   Sep 26th,   2016  started
#   Sep 27th,   2016  updated
#   Sep 28th,   2016  updated
#   Sep 29th,   2016  updated.
#   Sep 30th,   2016  updated.
#
# To do:
#  -
# ----------------------------------------------------------------------
if (!require(caret))
  install.packages('caret')
if (!require(e1071))
  install.packages('e1071')

library('caret')
library('e1071')

# -----------------------------------------------------------------------------
# Common functions
# -----------------------------------------------------------------------------
CalculateAccuracy <- function(confusion.matrix) {
  # Computes the accuracy value based on the confusion matrix
  #
  # Args:
  #   confusion.matrix: the confusion matrix with the values of predicting.
  #
  # Returns:
  #   The accuracy value.
  TN <- FN <- FP <- TP <- 0
  tryCatch ({TN <- confusion.matrix[1, 1]}, error=function(e){})  
  tryCatch ({FN <- confusion.matrix[2, 1]}, error=function(e){})
  tryCatch ({FP <- confusion.matrix[1, 2]}, error=function(e){})
  tryCatch ({TP <- confusion.matrix[2, 2]}, error=function(e){})
  accuracy <- (TP + TN) / (TN + FN + FP + TP)
  return(accuracy)
}
# -----------------------------------------------------------------------------

# initializes execution environment.
rm(list=ls())
setwd('~/Workspace/doutorado/disciplinas/mo444b/atividades/2') 

# reads raw data from file.
raw.data <- read.csv(file = './data/data1.csv', header = TRUE, sep = ',')

# selects 80% of raw data for train.
train.raw.data <- raw.data[trunc(nrow(raw.data) * 0.8), ]

# initializes cost and gamma grid.
grid <- expand.grid(cost = c(2 ** -5, 2 ** -2, 2 ** 0, 2 ** 2, 2 ** 5),
        gamma = c(2 ** -15, 2 ** -10, 2 ** -5, 2 ** 0, 2 ** 5))
accuracy.final <- 0

# performs the external cross-validation using 5-folds methods. 
external.folds <- createFolds(train.raw.data, k = 5, returnTrain = TRUE)
for (e in external.folds) {
  external.train.data <- raw.data[e, ]
  external.test.data  <- raw.data[-e, ]
  internal.folds <- createFolds(external.train.data, k = 3)
  accuracy.max <- 0
  for (i in internal.folds) {
    internal.train.data <- external.train.data[i,]
    internal.test.data  <- external.train.data[-i,]

    #h.max.cost<-0
    #h.max.gamma<-0
    for (cost.i in 1:5) {
      for (gamma.j in 1:5) {
        internal.svm.fit <-
          svm(clase ~ .,
              data = internal.train.data,
              cost = grid$cost[cost.i],
              gama = grid$gamma[gamma.j],
              kernel="radial")
        
        internal.svm.probs <- predict(internal.svm.fit, internal.test.data)
        #internal.svm.pred  <- rep(0, nrow(internal.test.data))
        #internal.svm.pred[internal.svm.probs > 0.5] <- 1
        #internal.svm.pred  <- rep(0, nrow(internal.test.data))
        internal.svm.pred <- ifelse(internal.svm.probs > 0.5, 1, 0)
        
        #accuracy <-CalculateAccuracy(table(internal.svm.pred, internal.test.data$clase))
        internal.svm.error <- mean(internal.svm.pred !=  internal.test.data$clase)
        internal.accuracy <- 1 - internal.svm.error
        if ( internal.accuracy > accuracy.max ){
          accuracy.max <- internal.accuracy
          h.max.cost <- grid$cost[cost.i]
          h.max.gamma <- grid$gamma[gamma.j]
        }
      }
    }
  }
  external.svm.fit <-
    svm(clase ~ .,
        data = external.train.data,
        cost = h.max.cost,
        gama = h.max.gamma,
        kernel="radial")
  
  external.svm.probs <- predict(external.svm.fit, external.test.data)
  # external.svm.pred  <- rep(0, nrow(external.test.data))
  # external.svm.pred[external.svm.probs > 0.5] <- 1
  external.svm.pred   <- ifelse(external.svm.probs > 0.5, 1, 0)
  external.svm.error  <- mean(external.svm.pred !=  external.test.data$clase)
  external.accuracy   <- 1 - external.svm.error
  
  #accuracy <-CalculateAccuracy(table(external.svm.pred, external.test.data$clase))
  accuracy.final <- external.accuracy + accuracy.final
}
  
cat(' accuracy after cross validation = ', accuracy.final/5, '\n')
cat(' cost and gama to use on classifier = ', h.max.cost,' and ', h.max.gamma, '\n')

final.folds <- createFolds(raw.data, k = 3)
final.accuracy <- 0
for (e in final.folds) {
  final.train.data <- raw.data[e, ]
  final.test.data  <- raw.data[-e, ]
  final.svm.fit <-
    svm(clase ~ .,
        data = final.train.data,
        cost = h.max.cost,
        gama = h.max.gamma, 
        kernel="radial")
  
  final.svm.probs <- predict(final.svm.fit, final.test.data)
  # final.svm.pred  <- rep(0, nrow(final.test.data))
  # final.svm.pred[final.svm.probs > 0.5] <- 1
  
  final.svm.pred   <- ifelse(final.svm.probs > 0.5, 1, 0)
  final.svm.error  <- mean(final.svm.pred !=  final.test.data$clase)
  local.accuracy   <- 1 - final.svm.error
  
  final.accuracy <- local.accuracy + final.accuracy
}
cat(' accuracy on final data set = ', final.accuracy/3, '\n')
