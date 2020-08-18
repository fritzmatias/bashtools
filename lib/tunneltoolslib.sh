#! /bin/bash
# it is expected a name convention on your ~/.ssh/config file 
# where the connection has the same repo name

. corelib.sh
. gitlib.sh

starttunnels(){
local repoDir=$1
isGitRepo && repoDir=$(basename $(gitRepoLocalRootPath|sed -e 's/.git//g'))
require repoDir
for host in $(grep $(basename $repoDir) ~/.ssh/config | sed -e 's/[ ]*Host[ ]*//g;s/[ ]*$//g'); do
  ps -fax|grep ssh |grep "$host" || ssh -NfT $host
done
};export -f startTunnels

lstunnels(){
local repoDir=$1
isGitRepo && repoDir=$(basename $(gitRepoLocalRootPath|sed -e 's/.git//g'))
require repoDir
  ps -fax|grep ssh |grep "$repoDir" |grep -v grep| sort -s 
}; export -f lstunnels

stoptunnels(){
local repoDir=$1
  lstunnels "$repoDir" | awk '{print $2}' | xargs kill 
}; export -f stopTunnels

