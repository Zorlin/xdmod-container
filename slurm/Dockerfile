# Build stage
FROM    centos:7 AS builder
LABEL   version="10.0.0" \
        description="Slurm collector for XDMoD" \
        maintainer="zorlin@gmail.com"

# Install dependencies and tools needed to build Slurm
RUN     yum -y update && \
        yum -y install	gcc python3-devel rpm-build && \
        yum -y install	perl-ExtUtils-MakeMaker perl-DBI perl-Switch && \
        yum -y install	mariadb-devel && \
        yum -y install  epel-release wget nano && \
        yum -y install  munge munge-libs munge-devel && \
        yum -y install  sudo openssl openssl-devel pam-devel \
        numactl numactl-devel hwloc hwloc-devel lua lua-devel \
        readline-devel rrdtool-devel ncurses-devel man2html \
        libibmad libibumad
RUN     set -o pipefail && echo "root:${ROOT_PASSWORD}" | chpasswd

#
# Fetch Slurm
#
RUN	wget https://download.schedmd.com/slurm/slurm-20.11.8.tar.bz2

#
# Build Slurm
#
RUN	rpmbuild -ta slurm-20.11.8.tar.bz2

# 
# Clean up
#
RUN	rm -r /slurm-20.11.8.tar.bz2

# Main stage
FROM	centos:7
WORKDIR /root/
COPY --from=builder /root/rpmbuild/RPMS/x86_64/slurm-20.11.8-1.el7.x86_64.rpm ./
RUN	yum -y install epel-release && yum -y install munge && \
        yum -y install slurm-20.11.8-1.el7.x86_64.rpm
RUN	rm slurm-20.11.8-1.el7.x86_64.rpm
RUN	chown -R root:root /run/munge /var/log/munge /var/lib/munge /etc/munge
COPY	run-munge.sh /usr/bin/run-munge
COPY	slurm-main.sh /usr/bin/slurm-main.sh
COPY	slurm-collect.sh /usr/bin/slurm-collect.sh
RUN	chmod 755 /usr/bin/run-munge /usr/bin/slurm-main.sh /usr/bin/slurm-collect.sh

CMD	["sleep", "infinity"]
