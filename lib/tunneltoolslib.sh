#! /bin/bash
# it is expected a name convention on your ~/.ssh/config file 
# where the connection has the same repo name

. corelib.sh
. gitlib.sh

lstunnels(){
local repoDir="$1"
[ "${repoDir}"x = x ] && repoDir="." 
repoDir=$(cd "$repoDir" && isGitRepo \
			&& basename $(echo $(gitRepoLocalRootPath)|sed -e 's/.git//g')\
			|| echo "${repoDir}" && error 2 \'${repoDir}\' is not a repo )
require repoDir
  ps -fax|grep ssh |grep "$repoDir" |grep -v grep| sort -s 
}; export -f lstunnels

starttunnels(){
local repoDir="$1"
[ "${repoDir}"x = x ] && repoDir="." 
repoDir=$(cd "$repoDir" && isGitRepo \
			&& basename $(echo $(gitRepoLocalRootPath)|sed -e 's/.git//g')\
			|| error 2 \'${repoDir}\' is not a repo )
require repoDir
for host in $(grep $(basename $repoDir) ~/.ssh/config | sed -e 's/[ ]*Host[ ]*//g;s/[ ]*$//g'); do
  ps -fax|grep ssh |grep "$host" || ssh -NfT $host && lstunnels "$repoDir"|grep "$host"
done
};export -f starttunnels

stoptunnels(){
local repoDir="$1"
  lstunnels "${repoDir}" | awk '{print $2}' | xargs kill 
}; export -f stoptunnels

