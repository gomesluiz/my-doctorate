# ----------------------------------------------------------------------
# Description:
#	  solutions for activity 3 (MO444)
#
# Version: 1.0
#
# Author:
#		Luiz Alberto, gomes.luiz@gmail.com
#
# History:
#   Sep 15th,   2016  started
#
# To do:
#  -
# ----------------------------------------------------------------------

if (!require(caret)) install.packages('caret')
if (!require(gbm)) install.packages('gbm')
if (!require(kernlab)) install.packages('kernlab')
if (!require(nnet)) install.packages('nnet')
if (!require(randomForest)) install.packages('randomForest')

library(caret)
library(gbm)
library(kernlab)
library(nnet)
library(randomForest)


# initializes execution environment.
rm(list=ls())
setwd('~/Workspace/doutorado/disciplinas/mo444b/atividades/3') 

ReadDataFile <- function(name){
  # Reads a data file in csv format.
  #
  # Args:
  #   name: file name to be read.
  # 
  # Returns:
  #   the data frame with rows and columns from file.
  #
  result <- read.csv(file = paste('./data/',name,sep=''), header = FALSE, sep = ' ')
  return(result)
}

InputByMean <- function(data){
  # Performs the input missing data by average.
  # 
  # Args:
  #   data: data frame to be processed.
  #
  # Returns:
  #   the data frame processed.
  #
  for(i in 1:ncol(data)){
    data[is.na(data[,i]), i] <- mean(data[,i], na.rm = TRUE)
  } 
  return(data)
}

Normalize <- function(data){
  # Performs the input missing data by means
  # 
  # Args:
  #   data: data frame to be processed.
  #
  # Returns:
  #   the data frame processed
  
  # remove columns with zero variance 
  result <- data[, sapply(data, function(n) { var(n, na.rm=TRUE) != 0 })]
  
  # scales the average to 0 and standard deviation to 1.
  result <- scale(result, center = TRUE, scale = TRUE)
  
  
  return(result)
}

# ------------------------------------------------------------------------------
# knn
# ------------------------------------------------------------------------------
CalculateAccuracyForKnn <- function(data, classes){
  pca.out    <- prcomp(data, scale.=T)
  pca.cumsum <- cumsum(pca.out$sdev^2)/sum(pca.out$sdev^2)
  pca.min    <- which(pca.cumsum >= 0.80)[1]

  z <- as.data.frame(pca.out$x[, 1:pca.min] %*% t(pca.out$rotation[, 1:pca.min]))
  z$Class <- classes
  
  set.seed(300)
  train.idx  <- createDataPartition(y=z$Class, p=0.80, list=FALSE)
  train.data <- z[train.idx, ]
  test.data  <- z[-train.idx, ]

  set.seed(400)
  knn.control <- trainControl(method = "repeatedcv", repeats = 1, number = 3)
  knn.grid <- expand.grid(k=c(1,5,11,15,21,25))
  knn.fit <- train(Class ~ ., data = train.data, 
                   method="knn", 
                   trControl=knn.control, 
                   preProcess=c("center", "scale"),
                   tuneGrid=knn.grid)
  
  knn.predict <- predict(knn.fit, newdata=test.data)
  knn.cm <- confusionMatrix(knn.predict, test.data$Class)
  
  return (knn.cm$overall['Accuracy'])
}

# ------------------------------------------------------------------------------
# svm
# ------------------------------------------------------------------------------
CalculateAccuracyForSvm <- function(data, classes){
  
 
  
  set.seed(300)
  data$Class <- classes
  train.idx  <- createDataPartition(y=data$Class, p=0.80, list=FALSE)
  train.data <- data[train.idx, ]
  test.data  <- data[-train.idx, ]

  set.seed(400)
  svm.control <- trainControl(method = "repeatedcv", repeats = 1, number = 3)
  svm.grid <- expand.grid(C=c(2**(-5), 2**(0), 2**(5), 2**(10)),
                          sigma=c(2**(-15), 2**(-10), 2**(-5), 2**(0), 2**(5)))
  svm.fit <- train(Class ~ ., data = train.data,
                   method="svmRadial",
                   trControl=svm.control,
                   preProcess=c("center", "scale"),
                   tuneGrid=svm.grid)

  svm.predict <- predict(svm.fit, newdata=test.data)
  svm.cm <- confusionMatrix(svm.predict, test.data$Class)

  return (svm.cm$overall['Accuracy'])

}

# ------------------------------------------------------------------------------
# nnet
# ------------------------------------------------------------------------------
CalculateAccuracyForNnet <- function(data, classes){

  set.seed(300)
  data$Class <- classes
  train.idx  <- createDataPartition(y=data$Class, p=0.80, list=FALSE)
  train.data <- data[train.idx, ]
  test.data  <- data[-train.idx, ]
  
  set.seed(400)
  nnet.control <- trainControl(method = "repeatedcv", repeats = 1, number = 3
  )
  nnet.grid <- expand.grid(size=c(10), decay=(0.5))
  
  nnet.fit <- train(Class ~ ., data = train.data,
                    method="nnet",
                    trControl=nnet.control,
                    preProcess=c("center", "scale"),
                    tuneGrid=nnet.grid, MaxNWts=5000)
  
  nnet.predict <- predict(nnet.fit, newdata=test.data)
  nnet.cm <- confusionMatrix(nnet.predict, test.data$Class)

  return (nnet.cm$overall['Accuracy'])
  
  
}

# ------------------------------------------------------------------------------
# rf
# ------------------------------------------------------------------------------
CalculateAccuracyForRf <- function(data, classes){
  
  set.seed(300)
 
  data$Class <- classes
  train.idx  <- trunc(nrow(data)*0.8)
  
  train.data <- data[1:train.idx, ]
  test.data  <- data[train.idx+1, ]
  
  set.seed(400)
  rf.control <- trainControl(method = "repeatedcv", repeats = 1, number = 3, search = "grid")
  rf.grid    <- expand.grid(mtry=c(10, 15, 20, 25))
  
  rf.fit <- train(Class ~ ., data = train.data,
                    method="rf",
                    metric="Accuracy",
                    trControl=rf.control,
                    #preProcess=c("center", "scale"),
                    tuneGrid=rf.grid,
                    ntree=c(100, 200, 300, 400))
  
  rf.predict <- predict(rf.fit, newdata=test.data)
  rf.cm <- confusionMatrix(rf.predict, test.data$Class)
  
  return (rf.cm$overall['Accuracy'])
}

# ------------------------------------------------------------------------------
# gbm
# ------------------------------------------------------------------------------
CalculateAccuracyForGbm <- function(data, classes){
  
  set.seed(300)
  data$Class <- classes
  train.idx  <- createDataPartition(y=data$Class, p=0.80, list=FALSE)
  train.data <- data[train.idx, ]
  test.data  <- data[-train.idx, ]
  
  set.seed(400)
  gbm.control <- trainControl(method = "repeatedcv", repeats = 1, number = 3, search = "grid")
  gbm.grid    <- expand.grid(interaction.depth=5, n.trees=c(30, 70, 100), shrinkage=c(0.1,0.5),
                             n.minobsinnode=10)
  
  gbm.fit <- train(Class ~ ., data = train.data,
                  method="gbm",
                  metric="Accuracy",
                  trControl=gbm.control,
                  preProcess=c("center", "scale"),
                  tuneGrid=gbm.grid)
  
  gbm.predict <- predict(gbm.fit, newdata=test.data)
  gbm.cm <- confusionMatrix(gbm.predict, test.data$Class)
  
  return (gbm.cm$overall['Accuracy'])
}


# reads raw data from file.
secom.data <- ReadDataFile('secom.data')
secom.data <- InputByMean(secom.data)
secom.data <- as.data.frame(Normalize(secom.data))
secom.data.labels <- ReadDataFile('secom_labels.data')
secom.data.classes <- as.factor(make.names(secom.data.labels$V1))

# knn.accuracy <- CalculateAccuracyForKnn(secom.data, secom.data.classes)
# cat(sprintf("Accuracy for knn was %.2f\n", knn.accuracy))
# svm.accuracy <- CalculateAccuracyForSvm(secom.data, secom.data.classes)
# cat(sprintf("Accuracy for svm was %.2f\n", svm.accuracy))
#nnet.accuracy <- CalculateAccuracyForNnet(secom.data, secom.data.classes)
#cat(sprintf("Accuracy for nnet was %.2f\n", nnet.accuracy))
rf.accuracy <- CalculateAccuracyForRf(secom.data, secom.data.classes)
cat(sprintf("Accuracy for rf was %.2f\n", rf.accuracy))
# gbm.accuracy <- CalculateAccuracyForGbm(secom.data, secom.data.classes)
# cat(sprintf("Accuracy for gbm was %.2f\n", gbm.accuracy))


