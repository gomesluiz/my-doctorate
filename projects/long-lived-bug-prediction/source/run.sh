#!/bin/bash

IMAGE=long-lived-bug-prediction-tf-gpu-v1

# docker run --rm -it --device=/dev/nvidiactl --device=/dev/nvidia-uvm --device=/dev/nvidia0 -v nvidia_driver_384.66:/usr/local/nvidia:ro -v /local:/local --name "${IMAGE}-c1" $IMAGE

#nvidia-docker run -it --rm --ipc=host --userns=host --name ${IMAGE}-c1 -v /home/lgomes/Workspace/doctorate/docker-metrics:/root ${IMAGE}:latest bash
#nvidia-docker run -it --ipc=host --userns=host -v /local:/local -v ~/Workspace/doctorate/metrics:/usr/src/app ${IMAGE}:latest bash
#nvidia-docker run -it --ipc=host --userns=host --mount "type=bind,src=$(pwd)/results/,dst=/home/lgomes/experiments/results/" --workdir /homes/lgomes/experiments/ ${IMAGE}:latest bash

#nvidia-docker run -it --ipc=host --userns=host -v ${PWD}/results/:/home/lgomes/experiments/results/ --workdir /home/lgomes/experiments/ ${IMAGE}:latest bash
nvidia-docker run -it --ipc=host --userns=host -v ${PWD}/results/:/home/lgomes/experiments/results/ --workdir /home/lgomes/experiments/ ${IMAGE}:latest python3 -u /home/lgomes/experiments/long-lived-prediction-w-dnn.py
