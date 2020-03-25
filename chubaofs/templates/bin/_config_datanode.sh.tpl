#!/bin/bash

set -ex
export LC_ALL=C

DISK_DIR=""
arr=(${CBFS_DATANODE_DISKS//,/ })  
for i in ${arr[@]}; do   
  Dir=$(echo $i | awk -F ":" '{print $1}')
  Quaota=$(echo $i | awk -F ":" '{print $2}')
  DataDir=""

  if [[ "$Dir" =~ ^/.* ]]; then
    DataDir=$Dir
  else
    DataDir="/cfs/data/$Dir"
  fi

  mkdir -p $DataDir
  test -z $DISK_DIR && DISK_DIR="$DataDir:$Quaota" || DISK_DIR=$DISK_DIR",$DataDir:$Quaota" 
done
echo "DISK_DIR="$DISK_DIR
if [ -z $DISK_DIR ];then
  exit 1
fi

# source init_dirs.sh
echo "before prepare config..."

jq -n \
  --arg port "$CBFS_DATANODE_PORT" \
  --arg prof "$CBFS_DATANODE_PROF" \
  --arg localIP "$CBFS_DATANODE_LOCALIP" \
  --arg logLevel "$CBFS_DATANODE_LOG_LEVEL" \
  --arg raftHeartbeat "$CBFS_DATANODE_RAFT_HEARTBEAT_PORT" \
  --arg raftReplica "$CBFS_DATANODE_RAFT_REPLICA_PORT" \
  --arg masterAddr "$CBFS_MASTER_ADDRS" \
  --arg exporterPort "$CBFS_DATANODE_EXPORTER_PORT" \
  --arg consulAddr "$CBFS_CONSUL_ADDR" \
  --arg disks "$DISK_DIR" \
  '{
    "role": "datanode",
    "listen": $port,
    "localIP": $localIP,
    "prof": $prof,
    "logDir": "/cfs/logs",
    "logLevel": $logLevel,
    "raftHeartbeat": $raftHeartbeat,
    "raftReplica": $raftReplica,
    "raftDir": "/cfs/data/datanode/raft",
    "consulAddr": $consulAddr,
    "exporterPort": $exporterPort,
    "masterAddr": $masterAddr,
    "disks": $disks
}' | jq '.masterAddr |= split(",")' | jq '.disks |= split(",")' > /cfs/conf/datanode.json

cat /cfs/conf/datanode.json
echo "after prepare config"


