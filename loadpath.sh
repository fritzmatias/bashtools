#!/bin/bash

addToPath(){
local path=$1
	PATH="$PATH:$path"
}

for path in $(cat ~/.path); do
	#export PATH="$PATH:$path"
	addToPath $path
done
export PATH=$(echo $PATH | tr ':' '\n' | sort -u |grep -v '^$'|tr '\n' ':')

. corelib.sh
. git_ps1.sh
