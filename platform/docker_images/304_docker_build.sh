#!/bin/bash
#
# Pull the latest version of all the docker images used in the mini-Internet

set -o errexit
set -o pipefail
set -o nounset

#images=(ixp ssh dns switch matrix vpn vlc hostm krill routinator webserver)

# If you want to use your custom docker containers and upload them into
# docker hub, change the docker username with your own docker username.
docker_name=miniinterneteth

#for image in "${images[@]}"; do
#    echo docker pull "${docker_name}/d_${image}"
#    if docker pull "${docker_name}/d_${image}" > /dev/null 2>&1; then
#        echo "$image pulled successfully."
#    else
#        echo "Failed to pull $image."
#        exit 1
#    fi
#done

images=(base base_supervisor host router measurement ssh)

for image in "${images[@]}"; do
    echo "Building $image..."
    if docker build --tag="d_${image}" "docker_images/${image}/" > /dev/null 2>&1; then
        echo "$image built successfully."
    else
        echo "Failed to build $image."
        exit 1
    fi
done
