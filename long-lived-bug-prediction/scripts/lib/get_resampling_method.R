resampling_methods = list(
  none = "none",
  boot = "boot",
  cv   = "cv",
  loocv = "LOOCV",
  lgocv = "LGOCV",
  repeatedcv = "repeatedcv"
)
get_resampling_method <- function(.method) {
  #' Returns the caret resampling method control.
  #'
  #' @param method The method of resampling.
  #'
  #' @return The caret resampling method control.
  #' 
  
  if (.method == resampling_methods[["cv"]]) {
    result <- trainControl(method = .method, number = 5)
  } else if (.method == resampling_methods[["repeatedcv"]]) {
    result <- trainControl(method = .method, number = 5, repeats = 2)
  } else if (.method %in% c(resampling_methods[["none"]]
                            , resampling_methods[["boot"]]
                            , resampling_methods[["loocv"]]
                            , resampling_methods[["lgocv"]])) {
    result <- trainControl(method = .method)
  } else {
    message("Invalid resampling method!")  
  }
  return (result)
}
