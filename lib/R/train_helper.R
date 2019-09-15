
library(futile.logger)

KNN  <- "knn"
NB   <- "nb"
NNET <- "nn"
RF   <- "rf"
SVM  <- "svm"
XB   <- "xgbTree"

train_classifiers <- c(
  KNN, 
  NB,
  NNET,
  RF, 
  SVM,
  XB 
)
names(train_classifiers) <- train_classifiers

DEFAULT_CONTROL <- trainControl(method = "repeatedcv", number = 5, repeats = 2, search = "grid")

DEFAULT_PREPROC <- c("BoxCox","center", "scale", "pca")
# "center": subtract mean from values.
# "scale" : divide values by standard deviation.
# ("center", "scale"): combining the scale and center transforms will 
#   standarize your data. Attributes will have a mean value of 0 and standard
#   deviation of 1.
# "range" : normalize values. Data values can be scaled in the range of [0, 1]
#    which is called normalization.

#' Training model with knn. 
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return a trained model knn.
train_with_knn <- function(.x, .y, .control=DEFAULT_CONTROL) {
  
  flog.trace("[train_with_knn] Training model with KNN")
  
  grid <- expand.grid(k = c(5, 11, 15, 21, 25, 33))
  # k: neighbors 
  
  result <- train(
    x = .x,
    y = .y,
    method = "knn",
    trControl = .control,
    tuneGrid  = grid,
    preProcess = DEFAULT_PREPROC
  )

  return(result)
}

#' Training model with Näive Bayes. 
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained model.
train_with_nb <- function(.x, .y, .control=DEFAULT_CONTROL) {
  
  flog.trace("[train_with_nb] Training model with NB")
  
  #grid <- expand.grid(
  #  fL        = c(0, 0.5, 1.0), # laplace correction
  #  usekernel = c(TRUE, FALSE)  # distribution type
  #  adjust    = c(0, 0.5, 1.0)  # bandwidth adjustment
  #)

  grid <- expand.grid(
    fL        = 0:5,               # laplace correction
    usekernel = c(TRUE, FALSE),    # distribution type
    adjust    = seq(0, 5, by = 1)  # bandwidth adjustment
  )
  
  result <- train(
    x = .x,
    y = .y,
    method = "nb",
    trControl = .control,
    tuneGrid  = grid,
    preProc   = DEFAULT_PREPROC
  )

  return(result)
}

#' Training model with neural network.
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained model.
train_with_nnet <- function(.x, .y, .control=DEFAULT_CONTROL) {
  
  flog.trace("[train_with_nnet] Training model with NNET")
  
  grid <- expand.grid(
    size  = c(10, 20, 30, 40),  # Hidden units 
    decay = (0.5)               # Weight decay
  )
  
  result <- train(
    x = .x,
    y = .y,
    method = "nnet",
    trControl = .control,
    tuneGrid  = grid,
    MaxNWts   = 5000,
    verbose   = FALSE,
    preProc   = DEFAULT_PREPROC
  )
  
  return(result)
}

#' Training model with random forest (ranger).
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained model.
train_with_rf <- function(.x, .y, .control=DEFAULT_CONTROL) {
  
  flog.trace("[train_with_rf] Training model with RF")
  
  grid <- expand.grid(
    mtry = c(25, 50, 75, 100)
  )
  
  result <- train(
    x = .x,
    y = .y,
    method = "rf",
    trControl = .control,
    tuneGrid  = grid,
    ntree   = 200,
    verbose = FALSE,
    preProc   = DEFAULT_PREPROC
  )
  
  return(result)
}

#' Training model with SVM RBF
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained model.
train_with_svm <- function(.x, .y, .control=DEFAULT_CONTROL) {
  
  flog.trace("[train_with_svm] Training model with SVM")
  
  grid <- expand.grid(
    C = c(
      2**(-5), 2**(0), 2**(5), 2**(10)
    ),
    sigma = c(
      2**(-15), 2**(-10), 2**(-5), 2**(0), 2**(5)
    )
  )
  
  result <- train(
    x = .x,
    y = .y,
    method    = "svmRadial",
    trControl = .control,
    tuneGrid  = grid,
    preProc   = DEFAULT_PREPROC
  )

  return(result)
}

#' Training model with XgBoost. 
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained model.
train_with_xb <- function(.x, .y, .control=DEFAULT_CONTROL) {
  
  flog.trace("[train_with_xb] Training model with XgBoost")
  
  grid <- expand.grid(
    nrounds = c(100, 200, 300, 400), # Boosting iterations
    max_depth = c(3:7),              # Max tree depth
    eta = c(0.05, 1),                # Shrinkage
    gamma = c(0.01),                 # Minimum loss reduction 
    colsample_bytree = c(0.75),      # Subsamble ratio of columns
    subsample = c(0.50),             # Subsample percentage
    min_child_weight = c(0)          # Minimum sum of instance weight
  )

  result <- train(
    x = .x,
    y = .y,
    method = "xgbTree",
    trControl = .control,
    tuneGrid  = grid,
    preProc   = DEFAULT_PREPROC
  )

  return(result)
}
#' Training model with a classifier pass as parameter. 
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained model.
train_with <- function(.x, .y, .classifier, .control=DEFAULT_CONTROL) {
  if (!.classifier %in% train_classifiers)
  {
    stop(sprintf("%s unknown classifier!", .classifier))
  }
  if (.classifier == KNN) {
    return(train_with_knn(.x, .y, .control))
  } else if (.classifier == NB) {
    return(train_with_nb(.x, .y, .control))
  } else if (.classifier == NNET) {
    return(train_with_nnet(.x, .y, .control))
  } else if (.classifier == RF) {
    return(train_with_rf(.x, .y, .control))
  } else if (.classifier == SVM) {
    return(train_with_svm(.x, .y, .control))
  } else if (.classifier == XB) {
    return(train_with_xb(.x, .y, .control))
  }
}
