#!/bin/bash

IMAGE=long-lived-bug-prediction-ml-v1
SHAREDIR=/home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/source/datasets
WORKDIR=/home/lgomes/Workspace/doctorate/projects/long-lived-bug-prediction/machine-learning/R
docker run  -it --ipc=host --userns=host -v ${SHAREDIR}/:${SHAREDIR}/ --workdir ${WORKDIR}/ ${IMAGE}:latest Rscript ${WORKDIR}/predict_long_lived_bug_e1_best_tune_rev1.R
