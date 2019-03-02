get_next_n_parameter <- function(all.lines, parameters)
{
  last.line <- all.lines[nrow(all.lines), ]
  start.parameter <- which(parameters$feature      == last.line$feature
                           & parameters$classifier == last.line$classifier
                           & parameters$resampling == last.line$resampling
                           & parameters$threshold  == last.line$threshold
                           & parameters$n_term     == last.line$n_term
                           & parameters$balancing  == last.line$balancing)
  
  if (is.na(start.parameter) | (start.parameter > nrow(parameters))) {
    start.parameter  <- 1
  } else {
    start.parameter <- start.parameter + 1
  }
  return(start.parameter)
}