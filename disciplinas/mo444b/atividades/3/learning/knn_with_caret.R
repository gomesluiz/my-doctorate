
if (!require(caret))
  install.packages('caret')

library(ISLR)
library(caret)

set.seed(300)
indxTrain <- createDataPartition(y=Smarket$Direction, p=0.75, list=FALSE)
training  <- Smarket[indxTrain, ]
testing   <- Smarket[-indxTrain, ]
#prop.table(table(training$Direction)) * 100
#prop.table(table(testing$Direction)) * 100
#prop.table(table(Smarket$Direction)) * 100
trainX <- training[, names(training) != "Direction"]
preProcValues <- preProcess(x = trainX, method = c("center", "scale"))
#preProcValues     

set.seed(400)
ctrl <- trainControl(method = "repeatedcv", repeats = 3)
knnFit <- train(Direction ~ ., data = training, method="knn", trControl=ctrl, preProcess=c("center", "scale"),
                tuneLength=20)
#knnFit
#plot(knnFit)
knnPredict <- predict(knnFit, newdata = testing)
matrix <- confusionMatrix(knnPredict, testing$Direction)
