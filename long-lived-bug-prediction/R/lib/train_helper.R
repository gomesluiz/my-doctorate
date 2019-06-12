KNN  <- "knn"
NB   <- "nb"
NNET <- "nn"
RF   <- "rf"
SVM  <- "svm"

DEFAULT_CONTROL <- trainControl(method = "repeatedcv", number = 5, repeats = 2, search = "grid")

#' Training model with SVM RBF
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained svm model.
train_with_svm <- function(.x, .y, .control=DEFAULT_CONTROL) {
  grid <- expand.grid(
    C = c(
      2**(-5), 2**(0), 2**(5), 2**(10)
    ),
    sigma = c(
      2**(-15), 2**(-10), 2**(-5), 2**(0), 2**(5)
    )
  )
  
  model <- train(
    x = .x,
    y = .y,
    method    = "svmRadial",
    trControl = .control,
    tuneGrid  = grid
  )

  return(model)
}

#' Training model with neural network.
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained neural network model.
train_with_nnet <- function(.x, .y, .control=DEFAULT_CONTROL) {
  grid <- expand.grid(
    size  = c(10, 20, 30, 40), 
    decay = (0.5)
  )
  
  model <- train(
    x = .x,
    y = .y,
    method = "nnet",
    trControl = control,
    tuneGrid  = grid,
    MaxNWts   = 5000,
    verbose   = FALSE
  )
  
  return(model)
}

#' Training model with neural network.
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained neural network model.
train_with_rf <- function(.x, .y, .control=DEFAULT_CONTROL) {
  grid <- expand.grid(
    mtry = c(10, 15, 20, 25)
  )

  model <- train(
    x = .x,
    y = .y,
    method = "rf",
    trControl = .control,
    tuneGrid  = grid,
    ntree   = 200,
    verbose = FALSE
  )
  
  return(model)
}

#' Training model with knn. 
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained knn.
train_with_knn <- function(.x, .y, .control=DEFAULT_CONTROL) {
  grid <- expand.grid(
    k = c(1, 5, 11, 15, 21, 25)
  )

  result <- train(
    x = .x,
    y = .y,
    method = "knn",
    trControl = control,
    tuneGrid  = grid
  )

  return(result)
}

#' Training model with Näive Bayes. 
#'
#' @param .x A dataframe with independable variables
#' @param .y A dataframe with dependable variable
#' @param .control A control Caret parameter
#'
#' @return A trained knn.
train_with_nb <- function(.x, .y, .control=DEFAULT_CONTROL) {
  
  grid <- expand.grid(
    fL        = c(0, 0.5, 1.0),
    usekernel = TRUE, 
    adjust    = c(0, 0.5, 1.0)
  )

  result <- train(
    x = .x,
    y = .y,
    method = "nb",
    metric = metric,
    trControl = .control,
    tuneGrid  = grid
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
train_with <- function(.x, .y, .control=DEFAULT_CONTROL) {
  if (classifier == KNN) {
    return(train_with_knn(.x, .y, .control))
  } else if (classifier == NB) {
    return(train_with_nb(.x, .y, .control))
  } else if (classifier == NNET) {
    return(train_with_nnet(.x, .y, .control))
  } else if (classifier == RF) {
    return(train_with_rf(.x, .y, .control))
  } else if (classifier == SVM) {
    return(train_with_svm(.x, .y, .control))
  }
}
