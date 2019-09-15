if (!require(fpc)) install.packages('fpc')

library(datasets)
library(fpc)

dat = attitude[, c(3, 4)]

set.seed(7)
d <- dist(dat, method="euclidean")

vmax <- 0
for (k in 2:10) {
  kml <- kmeans(dat, k, nstart = 5)
  stats <- cluster.stats(d, kml$cluster, silhouette = TRUE)
  v <- stats$avg.silwidth
  if (v > vmax) {
    vmax <- v
    kmax <- k
  }
}
  cat("k = ", kmax)

# kml <- kmeans(dat, 3, nstart=5)
# s <- cluster.stats(d, kml$cluster, silhouette=TRUE)
# print(s)

# plot(
#   dat,
#   col = (kml$cluster + 1) ,
#   main = "K-Means result with 2 clusters",
#   pch = 20,
#   cex = 2
# )