FROM rocker/verse:3.6
LABEL version="1.0"

ARG USER_ID
ARG GROUP_ID

# install R packages 
COPY install_packages.R /tmp/
WORKDIR /tmp/
RUN Rscript install_packages.R

# create the owner user
RUN addgroup --gid ${GROUP_ID} lgomes
RUN adduser --disabled-password --gecos '' --uid ${USER_ID} --gid ${GROUP_ID}

# create directories
WORKDIR /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/
RUN mkdir -p /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/R/lib/
RUN mkdir -p /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/source/datasets/
COPY  R/* /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/R/
COPY  R/lib/* /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/R/lib/
COPY  source/datasets/* /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/source/datasets/

RUN chown ${USER_ID}:${GROUP_ID} -R /home/lgomes
USER lgomes
