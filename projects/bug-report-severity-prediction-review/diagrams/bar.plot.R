bar.plot <- ggplot(data = count.by.category, aes(x = reorder(Category,-NumberOfPapers), y = NumberOfPapers, fill = Category)) +
  geom_bar(stat = "identity", color = "black", width = .4, size = .6) +
  scale_fill_manual(values = fill.colors) + 
  geom_rangeframe()+
  geom_text(aes(label = NumberOfPapers), vjust = -1.6, color = "black", size = 2) +
  labs(y ="Number of papers", x = "") +
  theme_tufte() +
  theme(axis.title.y = element_text(size = 6.5, color = "black"),
        axis.text.y  = element_text(size = 6.0, color = "black"),
        axis.text.x  = element_text(size = 6.5, color = "black"),
        legend.position = "none")
grid.arrange(bar.plot, nrow=1)