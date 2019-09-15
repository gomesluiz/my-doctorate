calculate_metrics <- function(.y_hat, .y_test) {
  cm <- confusionMatrix(data = .y_hat, reference = .y_test, positive = "Y")
  cm_tn <- cm$table[1, 1]
  cm_fn <- cm$table[1, 2]
  cm_tp <- cm$table[2, 2]
  cm_fp <- cm$table[2, 1]
  
  # sensitivity e recall: corresponde a taxa de acerto na classe positiva. Também 
  #                       é chamada de taxa de verdadeiros positivos. (TP/(TP+FN))
  # specificity: corresponde a taxa de acerto na classe negativa. (TN/(TN+FP))
  # balanced accuracy:
  # precision:  proporção de exemplos positivos classificados corretamente entre
  #             todos aqueles preditos como positivos. (TP/(TP+FP))
  # fmeasure:
  sensitivity.metric   <- sensitivity(data = .y_hat, reference = .y_test, positive = "Y")
  specificity.metric   <- sensitivity(data = .y_hat, reference = .y_test, positive = "N")
  precision.metric     <- precision(data = .y_hat, reference = .y_test)
  recall.metric        <- recall(data = .y_hat, reference = .y_test)
  fmeasure.metric      <- F_meas(data = .y_hat, reference = .y_test)
  balanced_acc.metric  <- (sensitivity.metric + specificity.metric) / 2
  balanced_acc.manual  <- (ifelse((cm_tp+cm_fn) == 0, 0, cm_tp/(cm_tp+cm_fn)) + ifelse((cm_tn+cm_fp) == 0, 0, cm_tn/(cm_tn+cm_fp))) / 2
  
  result <- data.frame(sensitivity  = sensitivity.metric,
              specificity  = specificity.metric,
              precision    = precision.metric, 
              recall       = recall.metric,
              fmeasure     = fmeasure.metric,
              balanced_acc = balanced_acc.metric,
              tp = cm_tp,
              fp = cm_fp,
              tn = cm_tn,
              fn = cm_fn,
              balanced_acc_manual = balanced_acc.manual)
  
  return (result)
}