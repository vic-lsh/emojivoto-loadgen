#!/bin/sh

# set -e

URL=localhost:8080
HTTP_URL=http://$URL
DUR_SECS=180

healthcheck() {
    echo "first, a healthcheck..."
    # first, sanity check to make sure the service is up and port is exposed
    curl $URL >/dev/null 2>&1 || { echo "healthcheck failed, make sure endpoint is up"; exit 1; }
}

timed_loadgen() {
    locust -t ${DUR_SECS}s --headless --users 100 --spawn-rate 1 -H $HTTP_URL
}

healthcheck && timed_loadgen

echo "finished loadgen for $DUR_SECS seconds!"
