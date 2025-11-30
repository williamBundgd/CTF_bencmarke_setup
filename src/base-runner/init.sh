#!/bin/bash
echo "VM started" > /dev/ttyS0

docker login https://registry.bench.test -u docker_usr -p docker_psw

docker run --detach \
  --volume=/var/run/docker.sock:/var/run/docker.sock \
  --env=DRONE_RPC_PROTO=https \
  --env=DRONE_RPC_HOST=drone.bench.test \
  --env=DRONE_RPC_SECRET=whZfjQQpAyPISaIy5pm0axVsF9Z0oXeA \
  --env=DRONE_RUNNER_CAPACITY=1 \
  --env=DRONE_RUNNER_NAME=runner-vm \
  --env=DRONE_RUNNER_VOLUMES=/etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
  --env=DRONE_DOCKER_CONFIG=/root/.docker/config.json \
  --env=DRONE_RUNNER_LABELS=environment:vm \
  --volume /etc/ssl/certs/ca-certificates.crt:/etc/ssl/certs/ca-certificates.crt \
  --volume /root/.docker/config.json:/root/.docker/config.json \
  --restart=always \
  --name=runner \
  --env=DRONE_DEBUG=true \
  --env=DRONE_TRACE=true \
  --env=DRONE_RPC_DUMP_HTTP=true \
  drone/drone-runner-docker:1

# NOTE: Any images can be pushed to the local registry here if needed.
#       Also any other container can be run if desired.

docker info > /dev/ttyS0

i=0
while true
do
        status=$(docker ps -f name=runner -q)
        if [ ! -z "${status}" ]; then
                echo "VM runner is running $i: $(curl --max-time 10 -s -o /dev/null -w "%{http_code}" https://git.bench.test)" > /dev/ttyS0

                docker logs --since=21s runner &> /dev/ttyS0
                
        else
                echo "VM runner is down $i" > /dev/ttyS0
        fi
        sleep 20
        i=$(($i + 1))

done
