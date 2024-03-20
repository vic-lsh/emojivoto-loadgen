#!/bin/sh

 kubectl get -n emojivoto deploy -o yaml  \
     | linkerd inject --proxy-image docker.io/vicsli/lkd-proxy-dev25 --manual - > test.yaml

 # kubectl get -n emojivoto deploy -o json  \
 #     | linkerd inject --proxy-image docker.io/vicsli/lkd-proxy-dev25 --manual - > test.json
