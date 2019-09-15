CalculateAccuracyForRf <- function(data, classes){
  # Calculates the Gradient Boosting Machine
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

  gbm.control <- trainControl(method = "cv", number = 3, search = "grid")
  gbm.grid    <- expand.grid(interaction.depth=5, n.trees=c(30, 70, 100), shrinkage=c(0.1,0.5),
                             n.minobsinnode=10)

  internal.max.accuracy <- 0
  for(e in external.folds) {
    train.data <- external.train.data[e, ]
    test.data  <- external.train.data[-e, ]

    set.seed(400)
    gbm.fit <- train(Class ~ ., data = train.data,
                  method="gbm",
                  metric="Accuracy",
                  trControl=gbm.control,
                  #preProcess=c("center", "scale"),
                  tuneGrid=gbm.grid)

    gbm.predict <- predict(gbm.fit, newdata=test.data)
    gbm.cm <- confusionMatrix(gbm.predict, test.data$Class)

    internal.accuracy <- gbm.cm$overall['Accuracy']
    if ( internal.accuracy >  internal.max.accuracy ){
      internal.max.accuracy <- internal.accuracy
      internal.best.interaction.depth    <- rf.fit$bestTune$interaction.depth
      internal.best.n.trees   <- rf.fit$bestTine$n.trees
      internal.best.shrinkage   <- rf.fit$bestTine$shrinkage
      internal.best.n.minobsinnode   <- rf.fit$bestTine$n.minobsinnode
      cat(sprintf("[Rf] interaction.depth= %d, n.trees= %d, shrinkage= %.2f, n.minobsinnode= %d, accuracy = %.5f\n",
                  internal.best.interaction.depth,
                  internal.best.n.trees,
                  internal.best.shrinkage,
                  internal.best.n.minobsinnode,
                  internal.max.accuracy))
    }

  }

  set.seed(400)
  external.gbm.fit <- train(Class ~ ., data = external.train.data,
                method="gbm",
                metric="Accuracy",
                trControl=gbm.control,
                #preProcess=c("center", "scale"),
                tuneGrid=expand.grid(interaction.depth=internal.best.interaction.depth,
                          n.trees=c(internal.best.n.trees),
                          shrinkage=c(internal.best.shrinkage),
                                           n.minobsinnode=internal.best.n.minobsinnode))

  external.gbm.predict <- predict(external.gbm.fit, newdata=external.test.data)
  external.gbm.cm <- confusionMatrix(external.gbm.predict, external.test.data$Class)

  return (external.gbm.cm$overall['Accuracy'])
}
