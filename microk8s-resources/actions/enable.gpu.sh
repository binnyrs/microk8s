#!/usr/bin/env bash

set -e

source $SNAP/actions/common/utils.sh

echo "Enabling NVIDIA GPU"
if lsmod | grep "nvidia" &> /dev/null ; then
  echo "NVIDIA kernel module detected"
else
  echo "Aborting: NVIDIA kernel module not loaded."
  echo "Please ensure you have CUDA capable hardware and the NVIDIA drivers installed."
  exit 1
fi

sudo sh -c "sed 's@${SNAP}@'"${SNAP}"'@g;s@${SNAP_DATA}@'"${SNAP_DATA}"'@g' $SNAP_DATA/args/containerd-nvidia.toml > $SNAP_DATA/args/containerd.toml"
sudo systemctl restart snap.${SNAP_NAME}.daemon-containerd
TRY_ATTEMPT=0
while ! (sudo systemctl is-active --quiet snap.${SNAP_NAME}.daemon-containerd) &&
      ! [ ${TRY_ATTEMPT} -eq 30 ]
do
  TRY_ATTEMPT=$((TRY_ATTEMPT+1))
  sleep 1
done
if [ ${TRY_ATTEMPT} -eq 30 ]
then
  echo "Snapped containerd not responding after 30 seconds. Proceeding"
fi

"$SNAP/microk8s-enable.wrapper" dns

echo "Applying manifest"
use_manifest gpu apply
echo "NVIDIA is enabled"
