## Clear R-workspace
rm(list=ls(all=TRUE))

## Set location of R-script as working directory
path.old <- getwd()
path.act <- dirname(sys.frame(1)$ofile)
setwd(path.act)

## Close all graphic devices
graphics.off()

## Load required package or install it if it is missing 
if (!require("dplyr")) install.packages("dplyr", dependencies = TRUE)
if (!require("googlesheets")) install.packages("googlesheets", dependencies = TRUE)
if (!require("ggplot2")) install.packages("ggplot2", dependencies = TRUE)
if (!require("ggthemes")) install.packages("ggthemes", dependencies = TRUE)
if (!require("gridExtra")) install.packages("gridExtra", dependencies = TRUE)
if (!require("reshape2")) install.packages("reshape2", dependencies = TRUE)
if (!require("tikzDevice")) install.packages("tikzDevice", dependencies = TRUE)
if (!require("UpSetR")) install.packages("UpSetR", dependencies = TRUE)

library(dplyr)
library(ggplot2)
library(ggthemes)
library(ggrepel)
library(gridExtra)
library(reshape2)
library(tikzDevice)
library(UpSetR)

## Preparing data
sheet.name   <- "survey-summary"
survey.sheet <- gs_title("bug-report-severity-prediction-survey-data")
survey.data  <- gs_read(ss=survey.sheet, ws = sheet.name, skip=2)
survey.data  <- survey.data[, c(7, 9)]
#survey.data  <- na.omit(melt(survey.data, id=c("Year")))
#survey.data  <- survey.data[, c(1, 3)] 
count.by.year <- survey.data %>% 
  group_by(Year) %>% 
  summarise(NumberOfPapers=n())
  
count.by.vehicle <- survey.data %>% 
  group_by(Vehicle) %>% 
  summarise(NumberOfPapers=n())

## Specify fundamental plot dimensions and parameters
width.cm  <- 6.5
height.cm <- 5.5
#fill.colors <- c('#f1a340', '#f7f7f7', '#998ec3')
fill.colors <- c('gray90', 'gray90', 'gray90', 'gray90', 'gray90')

## Specify global plot parameters
par(mar = c(3, 3, 2, 1),    # Margins
    mgp = c(1.5, 0.5, 0),   # Distance of axis labels (second value)
    tcl = -0.3)             # Length of axis tickmarks

## Plot bar chart
file.name.tex <- paste(sheet.name, '-by-year-in-bar.tex', sep='')
tikz(file.name.tex, width = width.cm, height = height.cm, standAlone = TRUE)
file.name.pdf <- paste(sheet.name, '-by-year-in-bar.pdf', sep='')
bar.plot <- ggplot(data = count.by.year
                   , aes(x = as.factor(Year), y = NumberOfPapers ,fill="gray23")) +
  geom_bar(stat = "identity", color = "gray23", fill="gray23"
                  , width = .4, size = .6) +
  geom_text(aes(label = NumberOfPapers), vjust = -1.6, color = "black", size = 5) +
  scale_y_continuous("Number of papers", limits = c(0,10)
                     , breaks = c(0, 2, 4, 6, 8, 10)) + 
  labs(x = NULL) +
  theme_classic() +
  theme(axis.title.y = element_text(size = 13, color = "black"),
        axis.text.y  = element_text(size = 13, color = "black"),
        axis.text.x  = element_text(size = 13, color = "black"),
        legend.position = "none")
grid.arrange(bar.plot, nrow=1)
dev.off()
tools::texi2dvi(file.name.tex, pdf=T)
system(paste(getOption('pdfviewer'), file.path(file.name.pdf)))
file.copy(file.name.pdf, paste('../source/figures/', file.name.pdf, sep=''), overwrite = TRUE)

## Plot donut chart
file.name.tex <- paste(sheet.name, '-by-source-in-dnt.tex', sep='')
tikz(file.name.tex, width = 3, height = 3, standAlone = TRUE)
file.name.pdf <- paste(sheet.name, '-by-source-in-dnt.pdf', sep='')
count.by.vehicle$fraction = count.by.vehicle$NumberOfPapers / sum(count.by.vehicle$NumberOfPapers)
count.by.vehicle = count.by.vehicle[order(count.by.vehicle$fraction), ]
count.by.vehicle$ymax = cumsum(count.by.vehicle$fraction)
count.by.vehicle$ymin = c(0, head(count.by.vehicle$ymax, n=-1))
dnt.plot = ggplot(count.by.vehicle, aes(fill=Vehicle, ymax=ymax, ymin=ymin, xmax=4, xmin=3)) +
  geom_rect(colour="grey23") +
  geom_text(aes(label=paste(round(fraction*100,0),sanitizeTexString("%"), sep="")
                , x=3.5
                , y=(ymin+ymax)/2)
                , size = 3.0
                , inherit.aes = TRUE
                , show.legend = FALSE) + 
  coord_polar(theta="y", start = 0) +
  xlim(c(0, 4)) +
  scale_fill_manual(values=c("gray60", "white")) +
  theme_tufte()+
  theme(legend.position=c(.5,.5))+
  theme(legend.title = element_blank())+
  theme(panel.grid=element_blank()) +
  theme(panel.border =element_blank()) +
  theme(axis.text=element_blank()) +
  theme(axis.title.x =element_blank()) +
  theme(axis.title.y =element_blank()) +
  theme(axis.ticks=element_blank())+
  theme(legend.text = element_text(size = 8.5)) 
grid.arrange(dnt.plot, nrow=1)
dev.off()
tools::texi2dvi(file.name.tex, pdf=T)
system(paste(getOption('pdfviewer'), file.path(file.name.pdf)))
file.copy(file.name.pdf, paste('../source/figures/', file.name.pdf, sep=''), overwrite = TRUE)

setwd(path.old)