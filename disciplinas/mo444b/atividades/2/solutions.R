# ----------------------------------------------------------------------
# Description:
#	  Solutions for activity 2 (MO444)
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

# initializes execution environment.
rm(list=ls())
setwd('~/Workspace/doutorado/disciplinas/mo444b/atividades/2') 

# reads raw data from file.
raw.data <- read.csv(file = './data/data1.csv', header = TRUE, sep = ',')

# selects 80% of raw data for train.
raw.data.train <- raw.data[trunc(nrow(raw.data) * 0.8), ]

# initializes cost and gamma grid.
grid.costs  <- c(2 ** -5 , 2 ** -2 , 2 ** 0 , 2 ** 2, 2 ** 5)
grid.gammas <- c(2 ** -15, 2 ** -10, 2 ** -5, 2 ** 0, 2 ** 5)

# performs the external cross-validation using 5-folds methods. 
external.folds <- createFolds(raw.data.train, k = 5, returnTrain = TRUE)
external.final.accuracy <- 0
for (e in external.folds) {
  external.train.data <- raw.data[e, ]
  external.test.data  <- raw.data[-e, ]
  
  # performs the internal cross-validation using 3-folds methods. 
  internal.folds <- createFolds(external.train.data, k = 3, returnTrain = TRUE)
  internal.max.accuracy <- 0
  for (i in internal.folds) {
    internal.train.data <- external.train.data[i,]
    internal.test.data  <- external.train.data[-i,]

    # searchs in hyperparameters grid for the maximum accuracy.
    for (cost.pos in 1:5) {
      for (gamma.pos in 1:5) {
        
        # uses hyperparameters in grid to train model.
        internal.svm.fit <-
          svm(clase ~ .,
              data = internal.train.data,
              cost = grid.costs[cost.pos],
              gama = grid.gammas[gamma.pos],
              kernel="radial")
        
        # predicts with test data with internal svm model.
        internal.svm.probs <- predict(internal.svm.fit, internal.test.data)
        internal.svm.pred <- ifelse(internal.svm.probs > 0.5, 1, 0)
        internal.svm.error <- mean(internal.svm.pred !=  internal.test.data$clase)
        internal.accuracy <- 1 - internal.svm.error
        
        if ( internal.accuracy > internal.max.accuracy ){
          internal.max.accuracy <- internal.accuracy
          h.max.cost <- grid.costs[cost.pos]
          h.max.gamma <- grid.gammas[gamma.pos]
        }
      }
    }
  }
  # uses hyperparameters to train model
  external.svm.fit <-
    svm(clase ~ .,
        data = external.train.data,
        cost = h.max.cost,
        gama = h.max.gamma,
        kernel="radial")
  
  # predicts with test data with external svm model.
  external.svm.probs <- predict(external.svm.fit, external.test.data)
  external.svm.pred   <- ifelse(external.svm.probs > 0.5, 1, 0)
  external.svm.error  <- mean(external.svm.pred !=  external.test.data$clase)
  external.accuracy   <- 1 - external.svm.error
  
  external.final.accuracy <- external.accuracy + external.final.accuracy
}
  
cat(' accuracy after cross validation    = ', external.final.accuracy/5, '\n')
cat(' cost and gama to use on classifier = ', h.max.cost,' and ', h.max.gamma, '\n')

# performs the 3-folds method on all data.
final.folds <- createFolds(raw.data, k = 3, returnTrain = TRUE)
final.accuracy <- 0
for (e in final.folds) {
  final.train.data <- raw.data[e, ]
  final.test.data  <- raw.data[-e, ]
  
  # applies hyperparameters classifier on all data
  final.svm.fit <-
    svm(clase ~ .,
        data = final.train.data,
        cost = h.max.cost,
        gama = h.max.gamma, 
        kernel="radial")
  
  final.svm.probs <- predict(final.svm.fit, final.test.data)
  
  final.svm.pred   <- ifelse(final.svm.probs > 0.5, 1, 0)
  final.svm.error  <- mean(final.svm.pred !=  final.test.data$clase)
  final.accuracy.local   <- 1 - final.svm.error
  
  final.accuracy <- final.accuracy.local + final.accuracy
}
cat('classifier accuracy in all data set = ', final.accuracy/3, '\n')
