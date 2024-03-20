#!/bin/sh

curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/emojivoto.yml \
	  | kubectl apply -f -


