if (!require("ISLR"))
  install.packages("ISLR")

library(ISLR)

data("Smarket")
names(Smarket)

summary(Smarket)

`?`(Smarket)
attach(Smarket)
cor(Smarket[,-9])

train = (Year < 2005)
Smarket.2005 = Smarket[!train, ]
Direction.2005 = Direction[!train]

glm.fit <- glm(Direction ~ Lag1 + Lag2 + Lag3 + Lag4 + Lag5 + Volume,
              data = Smarket,
              family = binomial,
              subset = train)
glm.probs <- predict(glm.fit, Smarket.2005, type="response")
glm.pred <- rep("Down", nrow(Smarket.2005))
glm.pred[glm.probs > 0.5] = "Up"
table(glm.pred, Direction.2005)

mean(glm.pred == Direction.2005)
mean(glm.pred != Direction.2005)

# refit the model using 2 prodictors lag1 and lag2
glm.fit <- glm(formula = Direction ~ Lag1 + Lag2, data = Smarket, family = binomial, subset=train)
glm.probs <- predict(glm.fit, Smarket.2005, type="response")
glm.pred <- rep("Dow", nrow(Smarket.2005))
glm.pred[glm.probs > 0.5] = "Up"
table(glm.pred, Direction.2005)
mean(glm.pred == Direction.2005)

# Predict
predict(glm.fit, newdata = data.frame(Lag1=c(1.2,1.5), Lag2=c(1.1, -0.8)), type="response")

pairs(Smarket)
plot(Volume)