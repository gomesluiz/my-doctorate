#!/bin/bash
docker build -t long-lived-bug-prediction-tf-gpu-v1 \
    --build-arg USER_ID=$(id -u) \
    --build-arg GROUP_ID=$(id -g) .

