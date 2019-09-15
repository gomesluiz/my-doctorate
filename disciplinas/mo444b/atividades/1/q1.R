# ----------------------------------------------------------------------
# Description:
#		implements activity 1 of mo444.
#
# Versão 1.0
#
# Author:
#		Luiz Alberto, gomes.luiz@gmail.com
#
# History:
#   Sep 12th,   2016  question 1  started
#   Sep 13th,   2016  question 1  updated
#   Sep 14th,   2016  question 1  updated
#   Sep 17th,   2016  question 1  conclued.
# To do:
#  -
# ----------------------------------------------------------------------
if (!require("devtools"))
  install.packages("devtools")
if (!require("ggbiplot"))
  install_github("ggbiplot", "vqv")



# question 1
setwd('~/Workspace/doutorado/disciplinas/mo444b/atividades/1/data')
source.original <-
  read.csv(file = 'data1.csv', header = TRUE, sep = ',')
#names(source.original)
#summary(source.original)



pca.input   <- source.original[, 1:ncol(source.original) - 1]
#names(pca.input)

pca.output <- prcomp(pca.input, scale. = T)
#plot(pca.output, type = "l")
#names(pca.output)
#summary(pca.output)
pca.variance <-
  cumsum(pca.output$sdev ^ 2) / sum(pca.output$sdev ^ 2)
#print(pca.variance)

# 13 dimensions according to accumaltive variance and summary pca.output  are reponsible of 81% of
# data variance.

source.transformed <-
  as.data.frame(pca.output$x[, 1:13] %*% t(pca.output$rotation[, 1:13]))
# print(source.transformed)

# library(ggbiplot)
# g <- ggbiplot(
#   pca.output,
#   obs.scale = 1,
#   var.scale = 1,
#   ellipse.prob = 0.8,
#   ellipse = TRUE,
#   circle = TRUE,
#   choices = c(1, 2)
# )
# g <- g + scale_color_discrete(name = '')
# g <- g + theme(legend.direction = 'horizontal',
#                legend.position = 'top')
#print(g)

# question 2
# glm with original data
# train.input <- source.original[1:200, ]
# test.input <- source.original[201:476, ]
# glm.fit <- glm(clase ~ f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13,
#                data=train.input, family = binomial(link="logit") )
# #summary(glm.fit)
# glm.probs <- predict.glm(glm.fit, test.input, type="response" )
# glm.pred  <- rep(0, nrow(test.input))
# glm.pred[glm.probs > 0.5] = 1
# #print(source.original[201:476, 167])
# table(glm.pred, source.original[201:476, 167])

FnGlm <- function(formula,
                  data.train,
                  data.test,
                  preditive.column) {
  glm.fit <-
    glm(formula, data = data.train, family = binomial(link = "logit"))
  summary(glm.fit)
  glm.probs <- predict.glm(glm.fit, data.test, type = "response")
  glm.preditive  <- rep(0, nrow(data.test))
  glm.preditive[glm.probs > 0.5] = 1
  confusion <- table(glm.preditive, preditive.column)
  print(confusion)
}


FnGlm(
  formula = clase ~ f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10 + f11 + f12 + f13,
  data.train = source.original[1:200, ],
  data.test = source.original[201:476, ],
  preditive.column = source.original[201:476, 167]
)

FnGlm(
  formula = clase ~ source.transformed$f1 + source.transformed$f2 + source.transformed$f3 +
    source.transformed$f4 + source.transformed$f5 + source.transformed$f6 +
    source.transformed$f7 + source.transformed$f8 + source.transformed$f9 +
    source.transformed$f10 + source.transformed$f11 + source.transformed$f12 +
    source.transformed$f13 ,
  data.train = source.transformed[1:200, ],
  data.test = source.transformed[201:476, ],
  preditive.column = source.original[201:476, 167]
)
