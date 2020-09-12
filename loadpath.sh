#! /bin/bash

for path in $(cat ~/.path); do
	PATH="$PATH:$path"
done

. corelib.sh
. git_ps1.sh
