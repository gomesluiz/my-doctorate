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
if (!require("VennDiagram")) install.packages("VennDiagram", dependencies = TRUE)
if (!require("tikzDevice")) install.packages("tikzDevice", dependencies = TRUE)
if (!require("UpSetR")) install.packages("UpSetR", dependencies = TRUE)

library(dplyr)
library(googlesheets)
library(gridExtra)
library(reshape2)
library(tikzDevice)
library(UpSetR)

## Preparing data
sheet.name   <- "distribution-by-ml-algorithm"
survey.sheet <- gs_title("bug-report-severity-prediction-survey-data")
survey.data  <- gs_read(ss=survey.sheet, ws = sheet.name, skip=0)
survey.data  <- survey.data[, 2:18]
survey.data  <- na.omit(melt(survey.data, id=c("Category")))
survey.data  <- survey.data[, c(1, 3)] 
count.by.category <- survey.data %>% 
  group_by(Category) %>% 
  summarise(NumberOfPapers=n_distinct(value))
  
## Specify fundamental plot dimensions and parameters 
width.cm  <- 6.5
height.cm <- 5.5
#fill.colors <- c('#f1a340', '#f7f7f7', '#998ec3')
fill.colors <- c('gray90', 'gray90', 'gray90', 'gray90', 'gray90')

## Specify global plot parameters
par(mar = c(3, 3, 2, 1),    # Margins
    mgp = c(1.5, 0.5, 0),   # Distance of axis labels (second value)
    tcl = -0.3)             # Length of axis tickmarks

## Plot upset chart
file.name.tex <- paste(sheet.name, '-category-in-ups.tex', sep='')
file.name.pdf <- paste(sheet.name, '-category-in-ups.pdf', sep='')
categories = c("Distance" , "Ensemble" , "Probabilistic"
               ,"Optimization", "Searching", "Other")
papers.c1 <- subset(survey.data, Category==categories[1]) 
papers.c2 <- subset(survey.data, Category==categories[2])
papers.c3 <- subset(survey.data, Category==categories[3])
papers.c4 <- subset(survey.data, Category==categories[4])
papers.c5 <- subset(survey.data, Category==categories[5])
papers.c6 <- subset(survey.data, Category==categories[6])
papers.all=list(  Distance=unique(papers.c1$value)
                , Ensemble=unique(papers.c2$value)
                , Probabilistic=unique(papers.c3$value)
                , Optimization=unique(papers.c4$value)
                , Searching=unique(papers.c5$value)
                , Other=unique(papers.c6$value)
)
tikz(file.name.tex, width = width.cm, height = height.cm, standAlone = TRUE)
upset(fromList(papers.all), 
      sets = categories
      , mainbar.y.label = "Number of papers"
      , sets.x.label = ""
      , text.scale = 1.8
      , order.by = "freq")
dev.off()
tools::texi2dvi(file.name.tex, pdf=T)
system(paste(getOption('pdfviewer'), file.path(file.name.pdf)))
file.copy(file.name.pdf, paste('../source/figures/', file.name.pdf, sep=''), overwrite = TRUE)

setwd(path.old)