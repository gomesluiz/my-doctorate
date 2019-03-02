
if (!require('caret')) install.packages("caret", dependencies = c("Depends", "Suggests"))
if (!require('futile.logger')) install.packages("futile.logger", dependencies = c("Depends", "Suggests"))
if (!require('testit')) install.packages("testit", dependencies = c("Depends", "Suggests"))

library(testit)
library(caret)

BASEDIR <- "~/Workspace/doctorate/long-lived-bug-prediction/scripts/"
LIBDIR  <- paste(BASEDIR,"lib/", sep="")
source(paste(LIBDIR, "get_resampling_method.R", sep=""))

flog.threshold(TRACE)
flog.trace("Starting test get_resampling_method.")
assert("resampling method is none", get_resampling_method(resampling_methods[["none"]])$method == "none")
assert("resampling method is boot", get_resampling_method(resampling_methods[["boot"]])$method == "boot")
assert("resampling method is cv", get_resampling_method(resampling_methods[["cv"]])$method == "cv")
assert("resampling method is repeatedcv", get_resampling_method(resampling_methods[["repeatedcv"]])$method == "repeatedcv")
assert("resampling method is loocv", get_resampling_method(resampling_methods[["loocv"]])$method == "LOOCV")
assert("resampling method is lgocv", get_resampling_method(resampling_methods[["lgocv"]])$method == "LGOCV")
assert("resampling method is invalid", get_resampling_method("invalid")$method == "null")
flog.trace("Test get_resampling_method finished.")