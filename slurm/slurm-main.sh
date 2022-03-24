#!/bin/bash
echo "`date` executing $0"
# start time
if [ $# -lt 1 ]
then
   date -d `cat /xdmod-ingest/.xdmod_last_date`
   if [ $? -eq 0 ]; then
     STIME=`cat /xdmod-ingest/.xdmod_last_date`
   else
     STIME="2027-01-01T00:00:00"
   fi
else
   STIME=$1
fi

# end time
if [ $# -lt 2 ]
then
   ETIME=`date +%FT%T`
else
   ETIME=$2
fi

echo "`date` cutoff dates:" $STIME $ETIME

# collect data from different clusters
./slurm-collect.sh ${STIME} ${ETIME}
if [ $? -ne 0 ]; then
   echo "`date` SLURM collector failed"
   exit 1
fi
