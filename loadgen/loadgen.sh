#!/bin/sh

set -e

# first, sanity check to make sure the service is up and port is exposed
curl localhost:8080

locust --headless --users 100 --spawn-rate 1 -H http://localhost:8080
