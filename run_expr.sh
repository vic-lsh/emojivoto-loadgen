#!/bin/sh

set -e

# loadgen script assumes its pwd is its directory.
cd loadgen
./loadgen.sh
cd ..

# this may fail b/c loadgen overwhelmed k8s.
# if so, manually run this script to gather results.
./gather_trace.sh
