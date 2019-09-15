if (!require("ISLR"))
  install.packages("ISLR")

library(ISLR)

data("Smarket")
names(Smarket)

summary(Smarket)

`?`(Smarket)
attach(Smarket)
cor(Smarket[,-9])

glm.fit = glm(Direction ~ Lag1 + Lag2 + Lag3 + Lag4 + Lag5 + Volume,
              family = binomial,
              data = Smarket)
summary(glm.fit)

glm.probs <- predict(glm.fit, type="response")
length(glm.probs)

glm.probs[1:10]
contrasts(Direction)

glm.pred <- rep("Down", 1250)
glm.pred[glm.probs > 0.5] = "Up"
table(glm.pred, Direction)

mean(glm.pred == Direction)