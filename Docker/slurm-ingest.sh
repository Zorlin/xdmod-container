#!/bin/bash

# load galaxy-cpu
xdmod-shredder -r galaxy-cpu -f slurm -i /xdmod-ingest/xdmod-galaxy-cpu-*.log
# load zeus-cpu
xdmod-shredder -r zeus-cpu -f slurm -i /xdmod-ingest/xdmod-zeus-cpu-*.log
# load zeus-copyq
xdmod-shredder -r zeus-copyq -f slurm -i /xdmod-ingest/xdmod-zeus-copyq-*.log
# load magnus
xdmod-shredder -r magnus -f slurm -i /xdmod-ingest/xdmod-magnus-*.log
