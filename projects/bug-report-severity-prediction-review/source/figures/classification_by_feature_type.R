library(ggplot)
library(ggplot)
library(treemapify)

features_by_puplications <- read.csv("~/Documents/doutorado/papers/StateOfTheArtInBugReportSeverityPrediction/figures/features_by_puplications.csv")

tree_map_plot <- ggplot(features_by_puplications, aes(area=Count, fill=Type, label=Feature)) +
    geom_treemap() +
    geom_treemap_text(colour = "black", place = "centre", grow = TRUE) +
    scale_fill_brewer(palette = "Greys") +
    theme(legend.position = "bottom")

print(tree_map_plot)
  
