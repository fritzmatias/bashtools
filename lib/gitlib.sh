#! /bin/bash
##
## Setting the git branch and syncronized status into PS1 definition
##
## The comments defines the values preseted by the distribution thought ~/.bashrc
##
## Instalation:
##	copy the script to /home/${user}/
## 	execute the script inside the ~/.bashrc with: '. scriptName'

. corelib.sh

gitBranchTree(){
 command cd $(gitRepoLocalRootPath)
 git log --graph --color --decorate --oneline --all
}

gitBranchTreeDetailed(){
 command cd $(gitRepoLocalRootPath)
 git log --graph --color --decorate --all
}

gitrmdeleted(){
 command cd $(gitRepoLocalRootPath)
 local files=$(git ls-files --deleted)
    while [ -n "${files}" ] && git rm --cached $(echo "${files}" | head -2500 ) ; do
	files=$(git ls-files --deleted)
    done
}

gitshowdifffiles(){
local commit="$1"
	[ "${commit}"x == x ] && commit="HEAD~0" && info "you can set HEAD~n or commit id, HEAD~0 is the current commit" 
	echo "Diff files in commit ${commit} "
	git diff-tree --no-commit-id --name-status -r ${commit} 
}

gitBranchParent(){
local i=0;
local res=; 
local maxLog=$(command git log --oneline|wc -l)
while ( [ -z "$res" ] || [ "$1"x = "all"x ] ) && [ $i -lt $maxLog ] ; do 
    i=$(($i+1)); 
    res=$(git branch --contains HEAD~$i 2>/dev/null|grep -v $(gitCurrentBranch) 2>/dev/null ); 
    debug "checking which branch contains HEAD~$i - $res - $maxLog "; 
done
echo "$res"
};

gitMergeStatus(){
  command git branch --merged | awk '{print $1}' | grep -v '*' | xargs 
}; 

gitignore(){
local repoRoot=$(gitRepoLocalRootPath)
local file=.gitignore
local gitignorefile="${repoRoot}/${file}"
local criterias="$(echo "$@" | sort -u)"
local data=$(cat ${gitignorefile} 2>/dev/null )
local newline='
'
local newdata
	[ -z "${data}" ] && echo "$@" >>"${gitignorefile}" && return $?
	for c in ${criterias} ; do
	 	! echo ${data} | egrep '^'"${c}"'$' >/dev/null && newdata="${newdata}${newline}${c}" || info "criteria: ${c} exist" 
	done
	echo "Added: ${newdata} ${newline} to ${gitignorefile}"
	echo "${newdata}">>"${gitignorefile}" && return $?
}

gitclonefast(){
local url="$1";shift

	command git clone "${url}" $(urlPath "${url}"|sed -e 's/\//-/g;s/.git|@//g')
}

gitRepoLocalRootPath(){
if [[ "$PWD" != "${GITREPOLOCALROOTPATH}" ]]; then 
	export GITREPOLOCALROOTPATH=$(command git rev-parse --show-toplevel 2>/dev/null) ;
fi 
echo ${GITREPOLOCALROOTPATH} ;
}; 

isGitRepo(){
  command git branch >/dev/null 2>/dev/null 
  return $?
};

isNotMergeInProgress(){
 git merge HEAD >/dev/null 2>/dev/null
 return $?
}

gitCurrentBranch(){
  git branch | grep '^*' | colrm 1 2 
};

urlPath(){
local url="$1";
	## removes the protocol and domain
	#echo "${url}" | sed -e 's/^[a-zA-Z]\+\:\/\/[a-zA-Z0-9\.]\+\///g' 2>/dev/null
	echo "${url}" | sed -e 's/(^[a-zA-Z]+://)?([a-zA-Z0-9.:@]+)?([a-zA-Z0-9.]+/)//g' 2>/dev/null
}

ps1_gitType(){
	[ "$(git rev-parse --is-bare-repository)"x == "true"x ] && echo "bare" || echo "git" 
}

gitCurrentPushBranch(){
	git branch -vv | grep '^*'|cut -d'[' -f 2 | cut -d']' -f 1
}

ps1_showPush(){
local pendingPush=$(git rev-parse @{push}... 2>/dev/null| sed -e 's/\^//g' | sort -u |wc -l)
    [ ${pendingPush} -gt 1 ] && echo ":push $(gitCurrentPushBranch)"
}
