#!/bin/bash
. corelib.sh

resolveTimeToSeconds(){
local time=$1
local realTime;
 timeExp=$(echo $time|sed -e 's/h/\*60m/g;s/m/\*60s/g;s/s/*1\+/g;s/$/0/g')
 let realTime=$timeExp
 echo $realTime
}

isCacheExpired(){
local file=$1
local time=$2
local timeout=$3 #seconds before to expiration time
[ "$time"x = x ] && time=500
[ "$timeout"x = x ] && timeout=500
require file time timeout
local realTime=$(resolveTimeToSeconds $time)
require realTime
local fileLastUpdate=$(stat -s "$file" |tr ' ' '\n'|grep mtime|cut -d'=' -f2)
 info $file $time-${timeout}s , fileLastrUupdate: "$fileLastUpdate + offset: $realTime < now: $(date +%s) - $timeout" \
 && let "$fileLastUpdate + $realTime < $(date +%s) - $timeout" \
 && info $file expired \
 || (info $file $(let "remain= - $(date +%s) + $timeout + $fileLastUpdate + $realTime " && echo $remain; \
	 let h=$remain/3600;let m=\($remain/60\)-\(${h}*60\); let s=${remain}-\(${h}*60\)-\(${m}*60\);  \
	echo ${h}h${m}m${s}s) until expiration. && return 1)
}


