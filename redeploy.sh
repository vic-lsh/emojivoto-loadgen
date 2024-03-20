#/bin/sh

# the script does the following
#
# 1. gen new timestamp-based tag
# 2. rebuild proxy image using new tag
# 3. push new image to docker hub
# 4. tag new image as latest
# 5. generate current app k8s deployment config, with linkerd injection applied
# 6. modify deploy config to use our latest image
# 7. check new deploy config validity
# 8. apply new config
#
# it assumes the app (e.g., emojivoto) is already deployed:
# we're just updating the linkerd proxy it is using.

set -e

SCRIPT_DIR=$(pwd)

# docker stuff
TAG=$(date +%s)  # gen unique tag based on unix timestamp
IMAGE=vicsli/lkd-proxy-traced
TAGGED_IMAGE="$IMAGE:$TAG"
TAGGED_IMAGE_LATEST="$IMAGE:latest"

# k8s config stuff
APP_NAMESPACE=emojivoto
INJECTED_CFG_PATH=/tmp/injected.yaml
MODIFIED_CFG_PATH=/tmp/transformed.yaml

rebuild_binary() {
    echo "==== REBUILDING BINARY ===="
   
    # TODO: make dir configurable? at least move it into this directory
    cd ../linkerd2/proxy
    
    cargo build --release --bin linkerd2-proxy

    cd $SCRIPT_DIR
}

rebuild_docker_image() {
    echo "==== REBUILDING DOCKER IMAGE ($TAGGED_IMAGE) ===="

    cd ../linkerd2

    docker build -t $TAGGED_IMAGE -f ./Dockerfile-proxy .
    
    cd $SCRIPT_DIR
}

push_new_image() {
    echo "==== PUSHING $TAGGED_IMAGE as latest ===="
    
    docker tag $TAGGED_IMAGE $TAGGED_IMAGE_LATEST

    docker push $TAGGED_IMAGE
    docker push $TAGGED_IMAGE_LATEST
}

gen_injected_config() {
    echo "==== GETTING LINKERD INJECTED CONFIG ===="

    kubectl get -n $APP_NAMESPACE deploy -o yaml  \
     | linkerd inject --proxy-image docker.io/$IMAGE --manual - \
     > $INJECTED_CFG_PATH
}

gen_transformed_config() {
    echo "==== TRANSFORMING INJECTED CONFIG ===="
    
    python3 ./config_transform.py \
        -f $INJECTED_CFG_PATH \
        -o $MODIFIED_CFG_PATH \
        -i $IMAGE \
        -t latest
}

validate_config() {
    echo "==== VALIDATING CONFIG ===="

    kubeval $MODIFIED_CFG_PATH
}

redeploy() {
    echo "==== REDEPLOY ===="
    
    kubectl apply -f $MODIFIED_CFG_PATH
}

rebuild_binary \
    && rebuild_docker_image \
    && push_new_image \
    && gen_injected_config \
    && gen_transformed_config \
    && validate_config \
    && redeploy
