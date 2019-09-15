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
setwd('~/Workspace/doutorado/disciplinas/mo444b/atividades/1')
source('fn_glm.R')

input.data <-read.csv(file = './data/data1.csv', header = TRUE, sep = ',')
input.pca   <- input.data[, 1:ncol(input.data) - 1]

output.pca <- prcomp(input.pca, scale. = T)
output.pca.variance <- cumsum(output.pca$sdev ^ 2) / sum(output.pca$sdev ^ 2)
#print(pca.variance)

# 13 dimensions according to accumaltive variance and summary pca.output  are reponsible of 81% of
# data variance.

source.transformed <- as.data.frame(output.pca$x[, 1:13] %*% t(output.pca$rotation[, 1:13]))

# print(source.transformed)

input.train <- source.transformed[1:200,]
input.test  <- input.data[201:476,]
input.preditive.column <- input.data[201:476, 167]


df <- input.train
df$clase <- input.data[1: 200, 167]
print(df$clase)

FnGlm(
  formula = clase ~ f1 + f2 + f3 +
    f4 + f5 + f6 +
    f7 + f8 + f9 +
    f10 +f11 + f12 +
    f13 ,
  data.train = input.train,
  data.test = input.test,
  preditive.column = input.preditive.column
)
