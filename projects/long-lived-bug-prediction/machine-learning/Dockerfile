FROM rocker/verse:3.6
LABEL version="1.0"

ARG USER_ID
ARG GROUP_ID

# install R packages 
COPY install_packages.R /tmp/
WORKDIR /tmp/
RUN Rscript install_packages.R

# create the owner user
RUN addgroup --gid ${GROUP_ID} gomes
RUN adduser --disabled-password --gecos '' --uid ${USER_ID} --gid ${GROUP_ID} gomes

# create directories
WORKDIR /home/${USER_ID}/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/
#RUN mkdir -p /home/${USER_ID}/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/
#RUN mkdir -p /home/${USER_ID}/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/
COPY . /

RUN chown ${USER_ID}:${GROUP_ID} -R /home/${USER_ID}
USER ${USER_ID}