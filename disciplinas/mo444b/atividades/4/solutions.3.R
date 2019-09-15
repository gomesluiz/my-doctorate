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

if (!require(caret))
  install.packages(caret)
if (!require(cluster))
  install.packages(cluster)
if (!require(fpc))
  install.packages(fpc)

library(fpc)
library(caret)
library(cluster)

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
  cluster.data.scaled <- scale(cluster.data)
  
  set.seed(123)
  dd <- dist(cluster.data.scaled, method = "euclidean")
  
  
  # external cluster validation
  output <- data.frame(line=character())
  e.folds <-
    createFolds(
      cluster.data.class$x,
      k = 5,
      list = TRUE,
      returnTrain = TRUE
    )
  max.rand <- 0
  for (e in 1:5) {
    ## internal cluster validation.
    i.folds <-
      createFolds(
        cluster.data.class$x,
        k = 3,
        list = TRUE,
        returnTrain = TRUE
      )
    max.dunn <- 0
    for (k in 2:10) {
      dunn <- 0
      for (i in 1:3) {
        kmi <- kmeans(cluster.data.scaled[i.folds[[i]], ], k, nstart = 5)
        kmi.stats <-
          cluster.stats(dd, kmi$cluster, silhouette = FALSE)
        dunn <- dunn + kmi.stats$dunn

        output <- rbind(output, data.frame(line=sprintf(' i = %d, k = %d, dunn = %.10f\n', i, k, kmi.stats$dunn)))
      }
      dunn <- dunn / 3
      if (dunn > max.dunn) {
        max.dunn <- kmi.stats$dunn
        max.ki <- k
      }
    }

    output <- rbind(output, data.frame(line=sprintf(' max.ki = %d, max.dunn = %.10f\n', max.ki, kmi.stats$dunn)))

    ## external cluster validation
    classes <- as.numeric(cluster.data.class$x[e.folds[[e]]])
    kme <-
      kmeans(cluster.data.scaled[e.folds[[e]],], max.ki, nstart = 5)
    kme.stats <- kme.stats <- cluster.stats(dd, classes, kme$cluster, silhouette = FALSE)

    output <- rbind(output, data.frame(line=sprintf(' e = %d, max.ki = %d, max.dunn = %.10f\n', e, max.ki, kme.stats$corrected.rand)))
    if (kme.stats$corrected.rand > max.rand) {
      max.rand <- kme.stats$corrected.rand
      max.ke <- max.ki
    }
  }

  ## write the final k.
  output <- rbind(output, data.frame(line=sprintf(' max.ke = %d, max.rand = %.10f\n', max.ke, max.rand)))

  write.csv(output, file='./data/result.csv', row.names = FALSE, quote = FALSE)
  
}

main()
