library(datasets)
library(smotefamily)
data("iris")

unbalanced.data = iris[c(2, 9, 16, 23, 51:63), c(1, 2, 5)]
balanced.data = SMOTE(unbalanced.data[, 1:2]
                      , as.numeric(unbalanced.data[,3])
                      , K = 1
                      , dup_size = 0)