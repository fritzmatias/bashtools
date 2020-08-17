#! /bin/bash
set -f

for path in $(cat ~/.path); do
	PATH="$PATH:$path"
done

. corelib.sh

