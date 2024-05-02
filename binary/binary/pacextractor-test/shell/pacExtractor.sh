#!/bin/sh

# This basic program is used for unpacking .pac file of Spreadtrum Firmware used in SPD Flash Tool for flashing.
# can run in dash. dd, od, tr are used mainly
#
# Created : 2nd April 2022
# Author  : HemanthJabalpuri
#
# This file has been put into the public domain.
# You can do whatever you want with this file.

if [ $# -lt 2 ]; then
  echo "Usage: pacExtractor.sh file.pac outdir"
  exit
fi

pacf="$1"
outdir="$2"

mkdir -p "$outdir" 2>/dev/null

getData() {
  dd if="$pacf" bs=1 skip=$1 count=$2 2>/dev/null
}

getInt() {
  getData $1 4 | od -A n -t u4 | tr -d ' '
}

szVersion="$(getData 0 44)"
dwHiSize="$(getInt 44)"
dwLoSize="$(getInt 48)"
dwSize="$((dwHiSize*0x100000000+dwLoSize))"
partitionCount="$(getInt 1076)"

echo "--Version: $szVersion--"
echo "--PAC size: $dwSize--"
echo "--File Count: $partitionCount--"
echo

seekoff=2124
for i in $(seq $partitionCount); do
  hiPartitionSize="$(getInt $((seekoff+1532)))"
  loPartitionSize="$(getInt $((seekoff+1540)))"
  partitionSize="$((hiPartitionSize*0x100000000+loPartitionSize))"
  if [ $partitionSize -ne 0 ]; then
    filename="$(getData $((seekoff+516)) 512)"
    hiDataOffset="$(getInt $((seekoff+1536)))"
    loDataOffset="$(getInt $((seekoff+1552)))"
    partitionAddrInPac="$((hiDataOffset*0x100000000+loDataOffset))"
    echo "--Filename: $filename--"
    echo "--Size: $partitionSize--"
    echo "--Offset: $partitionAddrInPac--"

    dd if="$pacf" of="$outdir/$filename" iflag=skip_bytes,count_bytes status=progress bs=4096 skip=$partitionAddrInPac count=$partitionSize
    echo
  fi
  seekoff=$((seekoff+2580))
done
