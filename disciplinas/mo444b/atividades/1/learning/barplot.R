lda <- c(sempca=0.710, compca=0.50)
glm <- c(sempca=0.637, compca=0.50)

data <- structure(list(glm=c(0.637, 0.50),lda=c(0.710, 0.50)), .Names=c("GLM", "LDA"),
                  class="data.frame", row.names=c(NA, -2L))
colours<-c("blue", "green")
barplot(as.matrix(data), main = "", y="Accuracy", ylab = "xxx",ylim = 1,
        beside = T, col=colours)