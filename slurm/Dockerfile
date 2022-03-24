FROM    centos:7
LABEL   version="10.0.0" \
        description="Slurm collector for XDMoD" \
        maintainer="zorlin@gmail.com"

#
# Install tools, libraries:
#
RUN     yum -y update && \
        yum -y install	gcc python3-devel && \
        yum -y install  epel-release wget nano && \
        yum -y install  munge munge-libs munge-devel && \
        yum -y install  sudo openssl openssl-devel pam-devel \
        numactl numactl-devel hwloc hwloc-devel lua lua-devel \
        readline-devel rrdtool-devel ncurses-devel man2html \
        libibmad libibumad
RUN     set -o pipefail && echo "root:${ROOT_PASSWORD}" | chpasswd

#
# Fetch and extract Slurm
#
RUN	wget https://github.com/SchedMD/slurm/archive/refs/tags/slurm-20-11-8-1.tar.gz
RUN	tar xvf slurm-20-11-8-1.tar.gz 

#
# Build Slurm
#
WORKDIR	"/slurm-slurm-20-11-8-1"
RUN	./configure
RUN	make install

# 
# Clean up
#
RUN	"rm -r /slurm-slurm-20-11-8-1"

#
# Command to execute when container is started:
#
CMD     /bin/bash
