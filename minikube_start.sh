#!/bin/sh

minikube start \
    --cpus 64 \
    --memory 64g \
    --extra-config=kubelet.housekeeping-interval=10s
