#! /bin/bash
##
## Setting the git branch and syncronized status into PS1 definition
##
## The comments defines the values preseted by the distribution thought ~/.bashrc
##
## Instalation:
##	copy the script to /home/${user}/
## 	execute the script inside the ~/.bashrc with: '. scriptName'

. gitlib.sh

isRepoCommited(){
cachefile="$1"
[ "$cachefile"x == x ] && cachefile=$(gitCache) 
#buildCacheBG "${cachefile}"
 [ $(catCache  "${cachefile}" 2>/dev/null | wc -l ) -eq 0 ]

}

gitCache(){
local repoRoot="$(gitRepoLocalRootPath)"

}
 
gitCacheDisable(){
if [ "${OLDPS1}"x != "$PS1"x ]; then
	PS1=$OLDPS1;
fi
export GITCACHEENABLE=false;
info "use gitCacheEnable to set the git status format in the console."
}
 
isGitCacheEnable(){
	[ "${GITCACHEENABLE}"x == "true"x ]
}
 
ps1_gitType(){
	[ "$(git rev-parse --is-bare-repository)"x == "true"x ] && echo "bare" || echo "git" 
}
 
ps1_showUnsync(){
local cachefile=$1
         echo ':unsync(M:'$(catCache "${cachefile}" | egrep '^[ AMDRCU]{2,2}' 2>/dev/null | wc -l)',?:'$(catCache "${cachefile}" | egrep '^\?\?' 2>/dev/null | wc -l)')';
}
 
ps1_showPush(){
local pendingPush=$(git rev-parse @{push}... 2>/dev/null| sed -e 's/\^//g' | sort -u |wc -l)
    [ ${pendingPush} -gt 1 ] && echo ":push $(gitCurrentPushBranch)"
}
 
ps1_showOrigin(){
local origin=$(git remote get-url origin 2>/dev/null )
local remote=$(echo $origin | sed -e 's/.*:\/\///g;s/\.[a-zA-Z0-9\/\.-]*//g')
local baseName=$(basename ${origin} 2>/dev/null)
require origin remote baseName
	([ -z ${remote} ] && echo 'self') || (echo "${remote}" | egrep '^/|@' >/dev/null 2>&1 && echo "local/${baseName}") || echo "${remote}/${baseName}" 
}
 
ps1_cmdLineChar(){
#copied from /etc/profile
    if [ "`id -u`" -eq 0 ]; then
      echo '#'
    else
      echo '$'
    fi
}
 
ps1_showBranch(){
GIT_BRANCH_PARENT=$(gitMergeStatus)
GIT_BRANCH_CURRENT=$(gitCurrentBranch)
  if [ "$GIT_BRANCH_PARENT" ]; then 
	  echo "($GIT_BRANCH_PARENT) $GIT_BRANCH_CURRENT"
  else
	echo "$GIT_BRANCH_CURRENT"
  fi
}
 
export CUSTOM='\n'
gitCacheEnable(){
if isGitCacheEnable; then
	# fix multiple calls to this function
	warn "calling multiple times to gitCacheEnable."
fi

if [ "${OLDPS1}"x != "${PS1}"x ]; then
	export OLDPS1=$PS1
fi
export GITCACHEENABLE=true;
#gitCacheBashVarEnable # don't work yet,  the bachground processing generates new shells
info "using $(gitCache)"
#addCacheToIgnoreFile

## check if some color is set
if echo "$PS1" | grep '\\\[\\033\[' >/dev/null 2>&1 ; then
        PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
        PS1="${PS1}"\
"\$( [ "${GITCACHEENABLE}"x == truex ] && isGitRepo && echo '\[\033[01;30m\]'\$(ps1_gitType)':'\$(ps1_showOrigin)' : '\$(echo '\[\033[01;32m\]'\$(ps1_showBranch)'\[\033[00m\]' &&\
  cachefile=\$(gitCache) &&\
  if ! isRepoCommited \${cachefile}  ;then\
         echo '\[\033[01;31m\]'\$(ps1_showUnsync \${cachefile} );\
  else echo '\[\033[01;31m\]'\$(ps1_showPush);\
  fi)'\[\033[01;30m\]${CUSTOM} $(ps1_cmdLineChar)\[\033[00m\] ')";

else
       PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
        PS1="${PS1}"\
"\$( [ "$GITCACHEENABLE"x == "true"x ] && isGitRepo && echo \$(ps1_gitType)':'\$(ps1_showOrigin)' : '\$(echo \$(gitCurrentBranch) &&\
  cachefile=\$(gitCache) &&\
  if ! isRepoCommited \${cachefile}  ;then\
         echo \$(ps1_showUnsync \${cachefile} );\
  else echo \$(ps1_showPush);\
  fi)'${CUSTOM} $(ps1_cmdLineChar) ')";

fi
PS1="${PS1}"' '

info "use gitCacheDisable to disable this format and the use of status caching."
}
########################################################################## 

gitCacheEnable
