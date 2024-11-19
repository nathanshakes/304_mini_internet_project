#!/bin/bash
#
# build all images and upload to the docker hub

set -o errexit
set -o pipefail
set -o nounset

images=(base base_supervisor host router ixp ssh measurement dns switch matrix vpn vlc hostm routinator krill webserver history)

for image in "${images[@]}"; do
    echo "Building $image..."
    if docker build --tag="d_${image}" "docker_images/${image}/" > /dev/null 2>&1; then
        echo "$image built successfully."
    else
        echo "Failed to build $image."
        exit 1
    fi
done
