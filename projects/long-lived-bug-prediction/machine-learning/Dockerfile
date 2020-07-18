FROM rocker/verse:3.6

# create directories
RUN mkdir -p /home/rstudio/project
RUN mkdir -p /home/rstudio/project/R
RUN mkdir -p /home/rstudio/project/lib
RUN mkdir -p /home/rstudio/project/data

# copy files
COPY R/*.R /home/rstudio/project/R/
COPY R/lib/*.R /home/rstudio/project/R/lib/

# install R-packages
RUN Rscript /home/rstudio/project/R/install_packages.R

