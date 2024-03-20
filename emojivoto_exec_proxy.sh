#!/bin/sh

kubectl exec -it $1 -n emojivoto --container linkerd-proxy -- bash
