#!/bin/bash
export STIME=$1
export ETIME=$2

# get_single_cluster_data function, arguments:
# CLUSTER - name of the cluster as in SLURM
# RESOURCE - name of the resource as in XDMOD
# PARTITIONS - list of partitions of the SLURM cluster to include in XDMOD resource
# NMT - number of threads per core, divide number of cores by the number of hardware threads
get_single_resource_data (){
	CLUSTER=$1
	RESOURCE=$2
	PARTITIONS=$3
	NMT=$4
	SLURM_TIME_FORMAT=standard
	TZ=UTC
	EXTRAOPT1=""
	if [ "$RESOURCE" == "zeus-gpu" ]
        then
	  EXTRAOPT1="-N a[081-91]"
	fi
sacct --clusters ${CLUSTER} -r ${PARTITIONS} ${EXTRAOPT1} --allusers \
--parsable2 --noheader --allocations --duplicates \
--format jobid,jobidraw,cluster,partition,qos,account,group,gid,user,uid,\
submit,eligible,start,end,elapsed,exitcode,state,nnodes,ncpus,reqcpus,reqmem,\
reqtres,alloctres,timelimit,nodelist,jobname \
--state CANCELLED,COMPLETED,FAILED,NODE_FAIL,PREEMPTED,TIMEOUT \
--starttime ${STIME} --endtime ${ETIME} > /xdmod-ingest/xdmod-${RESOURCE}-${STIME}-${ETIME}.log
sed -i -e 's/'"$CLUSTER"'/'"$RESOURCE"'/g' /xdmod-ingest/xdmod-${RESOURCE}-${STIME}-${ETIME}.log
if [ ! -z $NMT ]
then
  awk -v nmt="$NMT" 'BEGIN {FS="|";OFS="|"} {$19=$19/nmt} {print}' /xdmod-ingest/xdmod-${RESOURCE}-${STIME}-${ETIME}.log > tmpfile
  mv tmpfile /xdmod-ingest/xdmod-${RESOURCE}-${STIME}-${ETIME}.log
fi
}

. /xdmod-ingest/ingest.cfg
