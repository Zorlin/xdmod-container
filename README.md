# xdmod-container
This repository contains files for building Docker and Singularity images for [Open XDMoD](https://open.xdmod.org/).

It ships with an unsecured MariaDB instance (default CentOS 7 configuration; no `root` password is set, the test database is not removed, and the anonymous user is not removed), as MariaDB is not exposed outside of the container.

The `xdmod` container features a runloop that waits for files to appear in `/var/lib/XDMoD-ingest-queue/in`.  The file(s) are ingested into the database and will be moved to `/var/lib/XDMoD-ingest-queue/out` if successful or to `/var/lib/XDMoD-ingest-queue/error` if not.  Results of the operations are logged to `/var/log/xdmod/ingest-queue.log`.

## Custom ingest scripts
Collection and ingest scripts have been provided.

To use them...

Populate /xdmod-ingest/collect.cfg with steps for collecting data from your resources. For each resource, we run the function get_data.

The first field is the name of the cluster. The second field is the name of the resource in XDMoD for the queues you are selecting. Third field is the queues. Finally, there is an optional fourth field for threads per CPU on systems where you have Hyperthreading or SMT enabled.

```
echo "Collecting zeus cpu data..."
get_data zeus zeus-cpu "workq,debugq"
echo "Collecting magnus data..."
get_data magnus magnus "workq,debugq" 2
echo "Collecting galaxy cpu data..."
get_data galaxy galaxy-cpu "workq,longq" 2
```

Now, populate `/xdmod-ingest/ingest.cfg` with steps for ingesting the collected data.

```
# load zeus-cpu
xdmod-shredder -r zeus-cpu -f slurm -i /xdmod-ingest/xdmod-zeus-cpu-*.log
# load magnus
xdmod-shredder -r magnus -f slurm -i /xdmod-ingest/xdmod-magnus-*.log
# load galaxy-cpu
xdmod-shredder -r galaxy-cpu -f slurm -i /xdmod-ingest/xdmod-galaxy-cpu-*.log
```

Mount a working Slurm configuration and MUNGE key inside slurm-collector as `/etc/slurm/slurm.conf` and `/etc/munge/munge.key` respectively.

You can now run `slurm-main.sh` inside the *slurm-collector* container to gather data from your SLURM cluster(s), and `slurm-ingest.sh` inside the *xdmod* container to process and ingest the data. Finally, running `xdmod-ingestor` will do final processing and make it available to XDMoD.

## Docker
The Docker image listens on TCP port 80 by default. It has been modified with an expect script that automatically sets up basic settings for XDMoD, providing a working XDMoD installation out of the box.

An external directory can also be bind-mounted at `/var/lib/XDMoD-ingest-queue`.  The directory must have the following subdirectories:

  - `in`
  - `out`
  - `error`

These three directories will be created automatically by the entrypoint script if not present in `/var/lib/XDMoD-ingest-queue`.  Using an external directory allows processes outside the container to copy Slurm accounting log files to the `in` subdirectory and the entrypoint runloop will awake within 5 minutes and ingest the data.

### Example

The container image is built in this repository directory using:

```
$ cd Docker
$ ROOT_PASSWORD="<password>" docker build --rm --tag zorlin/xdmod:10.0.0 .
```

The following example illustrates the creation of an instance with persistent database and ingest queue directories:

```
$ mkdir -p /opt/xdmod/ingest-queue
$ mkdir -p /opt/xdmod/database
$ docker run --detach --restart unless-stopped \
    --name xdmod \
    --env CLUSTER_NAME="magnus" \
    --env RESOURCE_LOG_FORMAT="slurm" \
    --env EMAIL="example@protonmail.com" \
    --volume "/opt/xdmod/database:/var/lib/mysql:rw" \
    --volume "/opt/xdmod/ingest-queue:/var/lib/XDMoD-ingest-queue:rw" \
    --publish 80:80
    zorlin/xdmod:10.0.0
```

The `CLUSTER_NAME` and `RESOURCE_LOG_FORMAT` are used in the entrypoint XDMoD-start script as arguments to `xdmod-shredder` for resource manager log file ingestion. `RESOURCE_LOG_FORMAT` defaults to "slurm". `EMAIL` is used for XDMoD configuration and notices.

Once the instance is online, the ingest queue can be optionally activated:

```
$ docker exec -it xdmod /bin/bash -l
[container]> touch /var/lib/XDMoD-ingest-queue/enable
[container]> exit
```

At this point, copying files to `/tmp/XDMoD-Caviness/ingest-queue/in` will see them processed in the runloop.  Point a web browser to http://localhost/ to use XDMoD.

## Singularity

Singularity 3.0 or newer is required (3.2.1 was used in a previous production environment) for the network port mapping and support for instances (service-like containers).

Rather than bind-mounting directories at specific paths as outline above for Docker, with Singularity a writable overlay file system is a good option.  Any changes to the file system relative to the read-only container image are written to an external directory.  As with Docker, port 8080 is mapped to a host port to expose the web application.

### Example

The container image is built in this repository directory using:

```
$ cd Singularity
$ ROOT_PASSWORD="<password>" singularity build XDMoD-10.0.0.sif Singularity
```

The following example illustrates the execution of an instance with an overlay file system:

```
$ mkdir -p /opt/xdmod
$ singularity instance start --overlay /opt/xdmod --net --dns 10.65.0.13 \
    --network bridge --network-args "portmap=8080:8080/tcp" \
    --env CLUSTER_NAME="cc3" --env RESOURCE_LOG_FORMAT="slurm" \
    XDMoD-10.0.0.sif XDMoD-Caviness
```

The `CLUSTER_NAME` and `RESOURCE_LOG_FORMAT` are used in the entrypoint XDMoD-start script as arguments to `xdmod-shredder` for resource manager log file ingestion.  `RESOURCE_LOG_FORMAT` defaults to "slurm".  

Once the instance is online, XDMoD must be initialized and the ingest queue activated:

```
$ singularity shell instance://XDMoD-Caviness
[container]> xdmod-setup
    :
[container]> touch /var/lib/XDMoD-ingest-queue/in
[container]> touch /var/lib/XDMoD-ingest-queue/enable
[container]> exit
```

At this point, copying files to `/tmp/XDMoD-Caviness/upper/var/lib/XDMoD-ingest-queue/in` will see them processed in the runloop.  Point a web browser to http://localhost:8080/ to use the web application.

### Helper Scripts

The `sbin` directory includes a SysV-style script that can be used to start, stop, restart, and query status of instances of the Singularity container.

To start a new or existing instance with the default container image and overlay directory:

```
$ sbin/instance Caviness start
```

To use a different container image and overlay directory:

```
$ sbin/instance --overlay=/tmp/XDMoD --image=./XDMoD-uge.sif Farber start
```

The `status` action returns 0 if the instance is running, non-zero otherwise:

```
$ sbin/instance Farber status
```

The `--verbose` option increases the amount of output displayed by the command, and the `--help` option summarizes the command and all options.

In addition, the `systemd` directory contains a templated service unit that integrates Singularity instances with systemd for automated startup/shutdown.  Adding our Farber instance above looks like:

```
$ cp systemd/xdmod-template.service /etc/systemd/system/xdmod@Farber.service
$ systemctl daemon-reload
$ systemctl enable xdmod@Farber.service
$ systemctl start xdmod@Farber.service
```

## slurm-collector
An additional Docker image has been provided called slurm-collector. The purpose of this image is to provide a container for directly collecting Slurm data.

You can build it as follows:
```
$ cd slurm-collector
$ docker build --rm --tag zorlin/slurm-collector:latest
```

