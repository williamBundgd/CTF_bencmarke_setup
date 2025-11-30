#!/bin/bash
set -m
./entrypoint.sh /etc/docker/registry/config.yml &
while true
do
health=$(curl -k --write-out %{http_code} --silent --output /dev/null https://$REGISTRY_HTTPS_ADDR)
if [ "$health" -eq 200 ]; then
        echo "Registry is ready. Continue with setup..."
        break
else 
        echo "Registry is not ready. Waiting 5 seconds..."
        sleep 5
fi
done

# WARN: The code bellow will only work if the registry container has the docker.socket mounted to it
#       The part bellow also requires internet access at runtime
#       ---
#       If the docker.socket cannot be used, and/or if there will be no internet access,
#       use the VM runner to pull images at build time.

# Login in to the registry
docker login https://registry.bench.test -u docker_usr -p docker_psw

# NOTE: Any image can be pulled, tagged and pushed to the registry here
#       This is done at runtime, and requires the docker.socket and internet access.

docker pull docker:latest
docker tag docker:latest registry.bench.test/docker:1
docker push registry.bench.test/docker:1
docker image rm docker:latest
docker image rm registry.bench.test/docker:1

docker pull ubuntu:20.04
docker tag ubuntu:20.04 registry.bench.test/ubuntu:20.04
docker push registry.bench.test/ubuntu:20.04
docker image rm ubuntu:20.04
docker image rm registry.bench.test/ubuntu:20.04

docker pull alpine:latest
docker tag alpine:latest registry.bench.test/alpine:1
docker push registry.bench.test/alpine:1
docker image rm alpine:latest
docker image rm registry.bench.test/alpine:1

docker pull drone/git  # Used by Drone to clone git repo
docker pull drone/drone-runner-docker:1  # Drone Runner docker image

fg # Bring the registry process back to the foreground
