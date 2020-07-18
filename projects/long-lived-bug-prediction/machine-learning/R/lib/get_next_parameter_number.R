get_next_parameter_number <- function(.metrics.dataset, .parameters.dataset)
{
  last.row <- nrow(.metrics.dataset);
  
  if (last.row == 0) return (1);
  if (last.row >= nrow(.parameters.dataset)) return (-1);
  
  return(last.row + 1)
}