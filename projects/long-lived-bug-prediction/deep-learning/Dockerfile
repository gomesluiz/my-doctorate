FROM nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04
LABEL version="1.0" 

ARG USER_ID
ARG GROUP_ID 

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

RUN apt-get update --fix-missing && \
    apt-get install -y \
        wget bzip2 ca-certificates curl git apt-utils build-essential cmake pkg-config vim \
        libsm6 libxrender1 libfontconfig1 libx11-dev libatlas-base-dev libgtk-3-dev libboost-python-dev && \
    apt-get autoclean && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache 

# -- install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.5.11-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc
ENV CONDA_AUTO_UPDATE_CONDA=false

# -- install the sfsnet package and its dependences
COPY install_requirements.sh requirements.txt /tmp/ 
WORKDIR /tmp/
RUN pip install --upgrade pip && \
    sh install_requirements.sh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* ~/.cache

RUN addgroup --gid $GROUP_ID lgomes 
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID lgomes

WORKDIR /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/deep-learning
RUN mkdir -p /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/deep-learning/data/raw/
RUN mkdir -p /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/deep-learning/data/src/modeling/
COPY src/modeling/long-lived-bug-prediction-w-dnn.py /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/deep-learning/data/src/modeling/
COPY data/raw/*.csv /home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/deep-learning/data/raw/

RUN chown $USER_ID:$GROUP_ID -R /home/lgomes/
USER lgomes
