docker login https://registry.bench.test -u docker_usr -p docker_psw

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

docker pull drone/git  # Used by Drone to clone git repo
docker pull drone/drone-runner-docker:1  # Drone Runner docker image

# docker logout https://registry.bench.test
