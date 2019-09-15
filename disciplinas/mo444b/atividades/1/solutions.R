# ----------------------------------------------------------------------
# Description:
#	Atividade 1 da disciplina MO444
#
# Version: 1.0
#
# Author:
#		Luiz Alberto, gomes.luiz@gmail.com
#
# History:
#   Sep 12th,   2016  atividade 1  started
#   Sep 13th,   2016  atividade 1  updated
#   Sep 14th,   2016  atividade 1  updated
#   Sep 17th,   2016  atividade 1  conclued.
#
# To do:
#  -
# ----------------------------------------------------------------------

# installs the required packages.
if (!require("MASS"))
  install.packages("MASS")

require(MASS)

# sets the working directory
setwd('~/Workspace/doutorado/disciplinas/mo444b/atividades/1')

# common functions
CalculateAccuracy <- function(confusion.matrix) {
  # Computes the accuracy value based on the confusion matrix
  #
  # Args:
  #   confusion.matrix: the confusion matrix with the values of predicting.
  #
  # Returns:
  #   The accuracy value.
  TN <- confusion.matrix[1, 1]
  FN <- confusion.matrix[2, 1]
  FP <- confusion.matrix[1, 2]
  TP <- confusion.matrix[2, 2]
  accuracy <- (TP + TN) / (TN + FN + FP + TP)
  return(accuracy)
}
#------------------------------------------------------------------------------
# question 1
#------------------------------------------------------------------------------
original.data <- read.csv(file = './data/data1.csv', header = TRUE, sep = ',')

# the original data minus the last column.
pca.input  <- original.data[, 1:ncol(original.data) - 1]

# applies the pca method using prcomp function.
pca.output <- prcomp(pca.input, scale. = T)

# prints de pca output for analysis.
summary(pca.output)

# generates the original data using 13 pca components (according to previous 
# analysis).
transformed.data <- as.data.frame(pca.output$x[, 1:13] %*% 
                                    t(pca.output$rotation[, 1:13]))

# restores the last to column to data transformed set.
transformed.data$clase <- original.data[, 167]

#------------------------------------------------------------------------------
# question 2
#------------------------------------------------------------------------------

#
# GLM without PCA 
#

# defines the formula for all classifiers.
classifier.formula = clase ~ f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + 
      f11 + f12 + f13

# separates the data set in train and test data
original.data.train <- original.data[1:200,]
original.data.test <- original.data[201:476, ]

# defines preditive column
preditive.column <- original.data$clase[201:476]

# trains the glm classifier.
glm.fit   <- glm(classifier.formula, data = original.data.train, 
                 family = binomial(link = "logit"))

# tests predicties with data test.
glm.probs      <- predict.glm(glm.fit, original.data.test, type = "response")
glm.preditive  <- rep(0, nrow(original.data.test))
glm.preditive[glm.probs > 0.5] <- 1

# prints de confusion matrix
print('Confusion matrix for GLM without PCA')
print(table(glm.preditive, preditive.column), auto = TRUE)

# calculates an prints accuracy 
print('Accuracy for GLM without PCA')
accuracy <- CalculateAccuracy(table(glm.preditive, preditive.column))
print(accuracy)

#
# GLM with PCA 
#

# reads train data from transformed data by pca.
transformed.data.train <- transformed.data[1:200, ]

# trains the glm classifier.
glm.fit <- glm(classifier.formula, data = transformed.data.train, 
      family = binomial(link = "logit"))

# tests predicties with data test.
glm.probs <- predict.glm(glm.fit, original.data.test, type = "response")
glm.preditive  <- rep(0, nrow(original.data.test))
glm.preditive[glm.probs > 0.5] = 1

# prints de confusion matrix
print('Confusion matrix for GLM with PCA')
print(table(glm.preditive, preditive.column), auto = TRUE)

# calculates an prints accuracy 
print('Accuracy for GLM with PCA')
accuracy <- CalculateAccuracy(table(glm.preditive, preditive.column))
print(accuracy)

#------------------------------------------------------------------------------
# question 3
#------------------------------------------------------------------------------

#
# LDA without PCA 
#

# trains the lda classifier.
lda.fit <- lda(classifier.formula, data = original.data, 
               subset = original.data.train$x)

# tests predicties with data test.
lda.preditive  <- predict(lda.fit, original.data.test)
lda.class      <- lda.preditive$class

# prints de confusion matrix
confusion.matrix <- table(lda.class, preditive.column)
print('Confusion matrix for LDA without PCA')
print(confusion.matrix, auto = TRUE)

# calculates an prints accuracy 
print('Accuracy for LDA without PCA')
accuracy <- CalculateAccuracy(confusion.matrix)
print(accuracy)

#
# LDA with PCA 
#

# trains the lda classifier with transformed data by pca.
lda.fit <- lda(classifier.formula, data = transformed.data,
    subset = transformed.data.train$x)

# tests predicties with data test.
lda.preditive  <- predict(lda.fit, original.data.test)
lda.class      <- lda.preditive$class

# prints de confusion matrix
confusion.matrix <- table(lda.class, preditive.column)
print('Confusion matrix for LDA with PCA')
print(confusion.matrix, auto = TRUE)

# calculates an prints accuracy 
print('Accuracy for LDA with PCA')
accuracy <- CalculateAccuracy(confusion.matrix)
print(accuracy)