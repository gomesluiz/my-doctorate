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

# if (!require(caret)) install.packages('kmeans')
# if (!require(gbm)) install.packages('gbm')
# if (!require(kernlab)) install.packages('kernlab')
# if (!require(nnet)) install.packages('nnet')
# if (!require(randomForest)) install.packages('randomForest')
#
# ?library(kmeans)
# library(gbm)
# library(kernlab)
# library(nnet)
# library(randomForest)


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


# -----------------------------------------------------------------------------
# main function
# -----------------------------------------------------------------------------
main <- function() {
  # reads raw data from files.
  cluster.data <- ReadDataFile('cluster-data.csv')
  cluster.data.class <- ReadDataFile('cluster-data-class.csv')
  cluster.data = cluster.data[, c(1)]
  
  set.seed(123)
  distance <- dist(cluster.data, method="euclidean")
  
  max <- 0
  for (ki in 2:10) {
    kml <- kmeans(cluster.data, ki, nstart = 5)
    stats <- cluster.stats(distance, kml$cluster, silhouette = TRUE)
    if (stats$avg.silwidth > max) {
      max <- stats$avg.silwidth
      k <- ki
    }
  }
  
  cat("k = ", k)
  
  kml <- kmeans(cluster.data, 2, nstart = 5)
  plot(
     cluster.data,
     col = (kml$cluster + 1) ,
     main = "K-Means result with 2 clusters",
     pch = 20,
     cex = 2
   )
}

main()
