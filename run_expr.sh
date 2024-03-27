#!/bin/sh

set -e

apply_service_profiles() {
    echo "applying profiles.."
    kubectl apply -f ./emojivoto/training/service-profiles/emoji-svc-profile.yml
    kubectl apply -f ./emojivoto/training/service-profiles/voting-svc-profile.yml
    kubectl apply -f ./emojivoto/training/service-profiles/web-service-profile-with-timeout.yml
    # kubectl apply -f ./emojivoto/training/service-profiles/web-service-profile-with-retry-budget.yml

    echo "sleep to wait for profiles to take effect"
    sleep 10
}

apply_service_profiles

# loadgen script assumes its pwd is its directory.
cd loadgen
./loadgen.sh
cd ..

# this may fail b/c loadgen overwhelmed k8s.
# if so, manually run this script to gather results.
./gather_trace.sh
