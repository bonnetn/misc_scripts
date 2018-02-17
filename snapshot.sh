#!/bin/bash
set -e

ROTATION_COUNT=$1
SUFFIX=$2

BACKUP_COUNT="$(btrfs subvolume list /home/snapshots | grep $SUFFIX | wc -l)"
if [ "$BACKUP_COUNT" -eq 2 ]; then
  echo " [!!!] A backup previously failed !"

  TO_MOVE="/home/$(btrfs subvolume list /home/snapshots | cut -f9 -d" " | grep $SUFFIX | sort | head -n 2 | tail -n 1)"
  OLD="/home/$(btrfs subvolume list /home/snapshots | cut -f9 -d" " | grep $SUFFIX | sort | head -n 1)"

  echo " - Remounting /backup RW"
  mount -o remount,rw /backup

  echo " - Deleting corrupted /backup snapshot"
  btrfs subvolume delete "/backup/home/$(echo $TO_MOVE | cut -d"/" -f4 )" || true

  echo " - Sending snapshot"
  btrfs send -p "$OLD" "$TO_MOVE" | btrfs receive /backup/home/ 

  echo " - Remounting /backup RO"
  mount -o remount,ro /backup

  echo " - Removing previous /home snapshot $TO_REMOVE"
  btrfs subvolume delete "$OLD"
elif [ "$BACKUP_COUNT" -eq 1 ]; then
  echo " - Snapshot directory seems clean, continuing..."
else
  echo " - Snapshot count in /home != {1,2}, aborting..."
  exit 1
fi

# On trouve le plus récent (que ce soit $SUFFIX ou daily)
NEWEST="/home/$(btrfs subvolume list /home/snapshots | cut -f9 -d" " | sort -r | head -n 1)"
SNAPSHOT_NAME="$(date --iso-8601=min)_$SUFFIX"

echo " - Snapshotting home... $SNAPSHOT_NAME"
btrfs subvolume snapshot -r /home "/home/snapshots/$SNAPSHOT_NAME"
sync

echo " - Remounting /backup RW"
mount -o remount,rw /backup

echo " - Sending snapshot"
btrfs send -p "$NEWEST" "/home/snapshots/$SNAPSHOT_NAME" | btrfs receive /backup/home/ 


# Rotate /backup
function get_oldest {
  echo "$(btrfs subvolume list /backup/home | cut -f9 -d" " | sort | grep $SUFFIX)"
}

echo " - Rotating /backup snapshots."
while [ $(get_oldest | wc -l) -gt $ROTATION_COUNT ]; do
  echo $ROTATION_COUNT 
  oldest="/backup/$(get_oldest | head -n 1)"
  btrfs subvolume delete "$oldest"
done

echo " - Remounting /backup RO"
mount -o remount,ro /backup

TO_REMOVE="/home/$(btrfs subvolume list /home/snapshots | cut -f9 -d" " | grep $SUFFIX | sort | head -n 1)"

echo " - Removing previous snapshot $TO_REMOVE"
btrfs subvolume delete "$TO_REMOVE"
