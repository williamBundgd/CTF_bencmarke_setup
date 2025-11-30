# NOTE: Any image used by the runner / pipelines can be pulled and tagged here.
#       This populates the local docker image cache at build time, so no internet
#       is required for pulling images at run time.
#       ---
#       Please note that images cannot be pushed to the local registry at build time.
#       To push to the local registry, see init.sh

# 1. Add serial console to kernel boot params
sed -i 's/^default_kernel_opts="\(.*\)"/default_kernel_opts="\1 console=ttyS0"/' /etc/update-extlinux.conf

# 2. Update extlinux to apply changes
update-extlinux

# 3. Add getty on serial for login (optional)
echo "h0:12345:respawn:/sbin/getty -L 9600 ttyS0 vt100" >> /etc/inittab

# 4. (Optional) redirect syslog to ttyS0 for logging
echo "*.* /dev/ttyS0" >> /etc/syslog.conf
/etc/init.d/syslog restart

# docker pull docker:latest
# docker tag docker:latest registry.bench.test/docker:1
#
# docker pull ubuntu:20.04
# docker tag ubuntu:20.04 registry.bench.test/ubuntu:20.04

docker pull alpine:latest
docker tag alpine:latest registry.bench.test/alpine:1

# NOTE: Don't change the code below this comment. Only change the images above
docker pull drone/git  # Used by Drone to clone git repo
docker pull drone/drone-runner-docker:1  # Drone Runner docker image

cat /mnt/config/certCA.pem >> /etc/ssl/certs/ca-certificates.crt  # ca-certificates
poweroff
