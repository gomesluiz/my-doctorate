if (!require("MASS"))
  install.packages("MASS")

library(MASS)

doClassifyWithGlm <- function(formula,
                              data.train,
                              data.test,
                              preditive.column) {
  classifier.fit <-
    glm(formula, data = data.train, family = binomial(link = "logit"))
  #  summary(glm.fit)
  classifier.probs <-
    predict.glm(classifier.fit, data.test, type = "response")
  
  
  classifier.preditive  <- rep(0, nrow(data.test))
  classifier.preditive[classifier.probs > 0.5] = 1
  confusion <- table(classifier.preditive, preditive.column)
  print(confusion[1,1])
}

doClassifyWithLda <- function(formula,
                              data.all,
                              data.train,
                              data.test,
                              preditive.column) {
  #require(lda)
  classifier.fit <- lda(formula=formula, data = data.all, subset = data.train$x)

  #  summary(clasifier.fit)
  
  classifier.preditive  <- predict.lda(classifier.fit, data.test)
  classifier.class <- classifier.preditive$class
  
  confusion <- table(classifier.class, preditive.column)
  print(confusion)
}