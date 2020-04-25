#!/bin/bash

IMAGE=allansp-tf-gpu-v1

# docker run --rm -it --device=/dev/nvidiactl --device=/dev/nvidia-uvm --device=/dev/nvidia0 -v nvidia_driver_384.66:/usr/local/nvidia:ro -v /local:/local --name "${IMAGE}-c1" $IMAGE

nvidia-docker run -it --ipc=host --userns=host --name ${IMAGE}-c1 -v /local:/local -v /home/allan.pinto:/home/allan.pinto ${IMAGE}:latest bash

