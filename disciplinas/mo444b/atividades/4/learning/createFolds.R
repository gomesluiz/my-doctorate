

ind <- which(tissue != "placenta")
y <- tissue[ind]
X <- t( e[,ind] )


library(caret)
set.seed(1)

idx <- createFolds(y, k=10)
sapply(idx, length)