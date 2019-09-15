# ----------------------------------------------------------------------
# Description:
#	  solutions for activity 4 (MO444)
#
# Version: 1.0
#
# Author:
#		Luiz Alberto, gomes.luiz@gmail.com
#
# History:
#   Oct 20th,   2016  started
#
# To do:
#  -
# ----------------------------------------------------------------------

if (!require(caret)) install.packages(caret)
if (!require(e1071)) install.packages(e1071)
if (!require(fpc)) install.packages(fpc)

library(datasets)
library(fpc)
library(caret)
library(e1071)

# cleans up execution environment.
rm(list = ls())

# sets up path to data files.
setwd('~/Workspace/doutorado/disciplinas/mo444b/atividades/4')

# ------------------------------------------------------------------------------
# common functions
# ------------------------------------------------------------------------------
ReadDataFile <- function(name) {
  # Reads a data file in csv format.
  #
  # Args:
  #   name: file name to be read.
  #
  # Returns:
  #   the data frame with rows and columns from file.
  #
  result <-
    read.csv(
      file = paste('./data/', name, sep = ''),
      header = TRUE,
      sep = ','
    )
  return(result)
}

InputByMean <- function(data) {
  # Performs the input missing data by mean.
  #
  # Args:
  #   data: data frame to be processed.
  #
  # Returns:
  #   the data frame processed.
  #
  for (i in 1:ncol(data)) {
    data[is.na(data[, i]), i] <- mean(data[, i], na.rm = TRUE)
  }
  return(data)
}

NormalizeData <- function(data) {
  # Standardizes the columns for average 0 and standard deviation 1
  #
  # Args:
  #   data: data frame to be normalized.
  #
  # Returns:
  #   the data frame normalized.
  
  # first, remove columns with zero variance.
  result <-
    data[, sapply(data, function(n) {
      var(n, na.rm = TRUE) != 0
    })]
  
  # second, scales the average to 0 and standard deviation to 1.
  result <- scale(result, center = TRUE, scale = TRUE)
  
  return(result)
}
# ------------------------------------------------------------------------------



wssplot <- function(data, nc = 10, seed = 1234) {
  wss <- (nrow(data) - 1) * sum(apply(data, 2, var))
  for (i in 2:nc) {
    set.seed(seed)
    wss[i] <- sum(kmeans(data, centers = i)$withinss)
  }
  plot(1:nc,
       wss,
       type = "b",
       xlab = "Number of Clusters",
       ylab = "Within groups sum of squares")
}

# -----------------------------------------------------------------------------
# main function
# -----------------------------------------------------------------------------
main <- function() {
  # reads raw data from files.
  cluster.data <- ReadDataFile('cluster-data.csv')
  cluster.data.class <- ReadDataFile('cluster-data-class.csv')
  #cluster.data = cluster.data[, c(1)]
  
  set.seed(123)
  distance <- dist(cluster.data, method = "euclidean")
  
  max <- 0
  external.folds <- createFolds(cluster.data, k = 5, returnTrain = TRUE)
  external.final.accuracy <- 0
  for (e in external.folds) {
    cluster.external.data <- cluster.data[-e, ]
    #external.test.data  <- cluster.data[-e,]
    
    internal.folds <-
      createFolds(cluster.external.data,
                  k = 3,
                  returnTrain = TRUE)
    internal.max.accuracy <- 0
    for (i in internal.folds) {
      cluster.internal.data <- cluster.external.data[-i, ]
      #internal.test.data  <- external.train.data[-i, ]
      for (k in 2:10) {
        kml <- kmeans(cluster.internal.data, k, nstart = 5)
        stats <-
          cluster.stats(distance, kml$cluster, silhouette = TRUE)
        if (stats$avg.silwidth > max) {
          max <- stats$avg.silwidth
          kmax <- k
        }
      }
    }
  }
  cat("k = ", kmax)
  
  kml <- kmeans(cluster.data, kmax, nstart = 5)
  plot(
    cluster.data,
    col = (kml$cluster + 1) ,
    main = "K-Means result with 2 clusters",
    pch = 20,
    cex = 2
  )
}

main()
