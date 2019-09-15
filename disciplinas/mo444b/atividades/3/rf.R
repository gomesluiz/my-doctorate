CalculateAccuracyForRf <- function(data, classes){
  # Calculates the Random Forest accuracy
  #
  # Args:
  #   data
  #   classes
  #
  # Returns:
  #   the accuracy.
  #

  set.seed(300)
  data$Class <- classes
  external.idx.train  <- createDataPartition(y=data$Class, p=0.80, list=FALSE)
  external.train.data <- data[external.idx.train, ]
  external.test.data  <- data[-external.idx.train, ]
  external.folds      <- createFolds(external.train.data, k = 5, returnTrain = TRUE)

  rf.control <- trainControl(method = "cv", number = 3, search = "grid")
  rf.grid    <- expand.grid(mtry=c(10, 15, 20, 25))

  internal.max.accuracy <- 0
  for(e in external.folds) {
    train.data <- external.train.data[e, ]
    test.data  <- external.train.data[-e, ]

    set.seed(400)
    rf.fit <- train(Class ~ ., data = train.data,
                    method="rf",
                    metric="Accuracy",
                    trControl=rf.control,
                    #preProcess=c("center", "scale"),
                    tuneGrid=rf.grid,
                    ntree=c(100, 200, 300, 400))

    rf.predict <- predict(rf.fit, newdata=test.data)
    rf.cm <- confusionMatrix(rf.predict, test.data$Class)

    internal.accuracy <- nnet.cm$overall['Accuracy']
    if ( internal.accuracy >  internal.max.accuracy ){
      internal.max.accuracy <- internal.accuracy
      internal.best.mtry    <- rf.fit$bestTune$mtry
      internal.best.ntree   <- rf.fit$bestTine$ntree
      cat(sprintf("[Rf] mtry= %d, ntree= %d, accuracy = %.5f\n",
                  rf.fit$bestTune$mtry,
                  rf.fit$bestTune$ntree,
                  rf.cm$overall['Accuracy']))
    }

  }

  set.seed(400)
  external.rf.fit <- train(Class ~ ., data = train.data,
                  method="rf",
                  metric="Accuracy",
                  trControl=rf.control,
                  #preProcess=c("center", "scale"),
                  tuneGrid=expand.grid(mtry=c(internal.best.mtry)),
                  ntree=c(internal.best.ntree))

  external.rf.predict <- predict(external.rf.fit, newdata=external.test.data)
  external.rf.cm <- confusionMatrix(external.rf.predict, external.test.data$Class)

  return (external.rf.cm$overall['Accuracy'])
}
