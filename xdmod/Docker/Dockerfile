#
# Docker container-provisioning file for a container running a LAMP
# stack containing the XDMoD web application.
#
# Build
#
#   $ docker build --rm --tag local/xdmod:10.0.0 .
#
# Run
#
#   $ docker run --detach --restart unless-stopped --name XDMoD-Caviness \
#     --volume "$(pwd)/ingest-queue:/var/lib/XDMoD-ingest-queue:rw" \
#     --volume "$(pwd)/database:/var/lib/mysql:rw" \
#     --env CLUSTER_NAME="<cluster_name_for_xdmod-shredder>" \
#     --env RESOURCE_LOG_FORMAT="<resource_log_format_for_xdmod-shredder" \
#     --publish 80:80 \
#     local/xdmod:10.0.0
#

FROM    centos:7
LABEL   version="10.0.0" \
        description="XDMoD bundle containing database and web server" \
        maintainer="zorlin@gmail.com"

#
# Install tools, libraries:
#
RUN     yum -y update && \
        yum -y install  epel-release && \
        yum -y install  sudo wget gmp-devel cronie logrotate \
                        coreutils shadow-utils tar xz bzip2 gzip zip jq \
                        libreoffice chromium-headless librsvg2-tools expect \
                        which sendmail
RUN     set -o pipefail && echo "root:${ROOT_PASSWORD}" | chpasswd

#
# Install Apache and PHP:
#
RUN     yum -y install  httpd php php-cli php-gd php-gmp \
                        php-pdo php-xml php-pear-MDB2 php-pear-MDB2-Driver-mysql \
                        php-mbstring php-ldap php-pecl-apcu perl-Image-ExifTool

#
# Install MySQL:
#
RUN     yum -y install  mariadb-server mariadb

#
# Install XDMoD:
#
RUN     yum -y install https://github.com/ubccr/xdmod/releases/download/v10.0.0/xdmod-10.0.0-1.0.el7.noarch.rpm

#
# XDMoD uses an Apache virtual host on port 80:
#
EXPOSE  80/tcp

#
# Ensure a mountpoint/directory exists for the data ingest pipeline:
#
RUN     mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/in
RUN     mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/out
RUN     mkdir --parents --mode=0755 /var/lib/XDMoD-ingest-queue/error

#
# Command to execute when container is started:
#
COPY    --chown=0:0 XDMoD-start /usr/sbin/XDMoD-start
COPY    --chown=0:0 my.cnf.d/xdmod-tuning.cnf /etc/my.cnf.d/xdmod-tuning.cnf
COPY	--chown=0:0 xdmod.conf /etc/httpd/conf.d/xdmod.conf
COPY	--chown=0:0 run-xdmod-setup /usr/bin/run-xdmod-setup
COPY	--chown=0:0 slurm-ingest.sh /usr/bin/slurm-ingest.sh
RUN     chmod 0755 /usr/sbin/XDMoD-start
RUN     chmod 0644 /etc/my.cnf.d/xdmod-tuning.cnf
RUN     chmod 0755 /usr/bin/run-xdmod-setup
RUN     chmod 0755 /usr/bin/slurm-ingest.sh
CMD     /usr/sbin/XDMoD-start
