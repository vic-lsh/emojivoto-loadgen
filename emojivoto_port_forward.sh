#/bin/sh


kubectl -n emojivoto port-forward svc/web-svc 8080:80
