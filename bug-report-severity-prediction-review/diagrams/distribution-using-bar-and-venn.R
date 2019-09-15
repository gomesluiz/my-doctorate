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
library(ggplot2)
library(ggthemes)
library(gridExtra)
library(reshape2)
library(VennDiagram)
library(tikzDevice)
library(UpSetR)

## Preparing data
sheet.name   <- "distribution-by-feature-category"
survey.sheet <- gs_title("bug-report-severity-prediction-survey-data")
survey.data  <- gs_read(ss=survey.sheet, ws = sheet.name, skip=0)
survey.data  <- survey.data[, 2:23]
survey.data  <- na.omit(melt(survey.data, id=c("Category")))
survey.data  <- survey.data[, c(1, 3)] 
count.by.category <- survey.data %>% 
  group_by(Category) %>% 
  summarise(NumberOfPapers=n_distinct(value))
  
## Specify fundamental plot dimensions and parameters 
width.cm  <- 5.5
height.cm <- 5.5
#fill.colors <- c('#f1a340', '#f7f7f7', '#998ec3')
fill.colors <- c('gray90', 'gray90', 'gray90', 'gray90', 'gray90')

## Specify global plot parameters
par(mar = c(3, 3, 2, 1),    # Margins
    mgp = c(1.5, 0.5, 0),   # Distance of axis labels (second value)
    tcl = -0.3)             # Length of axis tickmarks

## Plot bar chart
file.name.tex <- paste(sheet.name, '-in-bar.tex', sep='')
file.name.pdf <- paste(sheet.name, '-in-bar.pdf', sep='')
tikz(file.name.tex, width = width.cm, height = height.cm, standAlone = TRUE)
source("bar.plot.R")
dev.off()
tools::texi2dvi(file.name.tex, pdf=T)
system(paste(getOption('pdfviewer'), file.path(file.name.pdf)))
file.copy(file.name.pdf, paste('../source/figures/', file.name.pdf, sep=''), overwrite = TRUE)

## Plot venn chart
file.name.tex <- paste(sheet.name, '-in-ven.tex', sep='')
file.name.pdf <- paste(sheet.name, '-in-ven.pdf', sep='')
categories = c("Unstructured Text" , "Qualitative Categorical" , "Qualitative Ordinal"
               ,"Quantitative Discrete", "Quantitative Continuous")
papers.c1 <- subset(survey.data, Category==categories[1]) 
papers.c2 <- subset(survey.data, Category==categories[2])
papers.c3 <- subset(survey.data, Category==categories[3])
papers.c4 <- subset(survey.data, Category==categories[4])
papers.c5 <- subset(survey.data, Category==categories[5])
papers.all=list(  UTX=unique(papers.c1$value)
                , CAT=unique(papers.c2$value)
                , ORD=unique(papers.c3$value)
                , DIS=unique(papers.c4$value)
                , CON=unique(papers.c5$value)
                )
tikz(file.name.tex, width = width.cm, height = height.cm, standAlone = TRUE)
#source("venn.plot.R")
upset(fromList(papers.all), 
      sets = c("UTX", "CAT", "ORD", "DIS", "CON"), sets.bar.color = "gray90",
      order.by = "freq")
dev.off()
tools::texi2dvi(file.name.tex, pdf=T)
system(paste(getOption('pdfviewer'), file.path(file.name.pdf)))
file.copy(file.name.pdf, paste('../source/figures/', file.name.pdf, sep=''), overwrite = TRUE)

setwd(path.old)