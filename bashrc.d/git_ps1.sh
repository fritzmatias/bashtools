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
 
isGitRepo(){
  command git branch >/dev/null 2>/dev/null 
  return $?
};export -f isGitRepo

catCache(){
	git status -s 2>/dev/null
}

isRepoCommited(){
cachefile="$1"
[ "$cachefile"x == x ] && cachefile=$(gitCache) 
#buildCacheBG "${cachefile}"
 [ $(catCache  "${cachefile}" 2>/dev/null | wc -l ) -eq 0 ]

}

gitCache(){
local repoRoot="$(gitRepoLocalRootPath)"
  echo "$repoRoot"
}
 
gitCacheDisable(){
if [ "$OLDPS1"x != x ] && [ "${OLDPS1}"x != "$PS1"x ]; then
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
 
ps1_showRelatedBranches(){
local git_branch_parent=$(gitMergeStatus)
  if [ "$git_branch_parent" ]; then 
	  echo "($git_branch_parent)"
  else
	  echo ""
 fi
}

ps1_showCurrentBranch(){
	gitCurrentBranch
}
 
isColorsSet(){
echo "$PS1" | grep '\\e\[' >/dev/null 2>&1 ||
echo "$PS1" | grep '\\\[\\033\[' >/dev/null 2>&1
}

export CUSTOM='\n'
gitCacheEnable(){
if isGitCacheEnable; then
	# fix multiple calls to this function
	debug "calling multiple times to gitCacheEnable."
fi

if [ "${OLDPS1}"x != "${PS1}"x ]; then
	export OLDPS1=$PS1
fi
export GITCACHEENABLE=true;

## check if some color is set
if isColorsSet; then
PS1='${debian_chroot:+($debian_chroot)}\[$(__format ${green2})\]\u@\h\[$(__format ${white})\]:\[$(__format ${boldStart}${blue})\]\w\[$(__format ${default})\]\$ '
        PS1="${PS1}"\
"\$( [ "${GITCACHEENABLE}"x == truex ] && isGitRepo \
  && echo '\['\$(__format ${gray2}${boldStart})'\]'\$(ps1_gitType)':'\$(ps1_showOrigin)' : '\$(echo '\['${default}${green}'\]'\$(ps1_showRelatedBranches)' \['${boldStart}${green}'\]'\$(ps1_showCurrentBranch)'\['${boldEnd}${default}'\]' \
  && cachefile=\$(gitCache)\
  && if ! isRepoCommited \${cachefile} ;then\
	  echo '\['${red}${boldStart}'\]'\$(ps1_showUnsync \${cachefile})'\['${default}'\]';\
	  echo '\['${red}${boldStart}'\]'\$(ps1_showPush)'\['${default}'\]';\
  else \
	echo '\['${red}${boldStart}'\]'\$(ps1_showPush);\
  fi)\[${default}\]'${CUSTOM} \$' \[${default}\] )";

else
       PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ ' 
       PS1="${PS1}"\
	      "\$( [ "$GITCACHEENABLE"x == "true"x ] \
	      && isGitRepo \
        && echo \$(ps1_gitType)':'\$(ps1_showOrigin)' : '\$( \
          echo \$(ps1_showRelatedBranches) \$(ps1_showCurrentBranch) \
          &&  cachefile=\$(gitCache) \
          &&  if ! isRepoCommited \${cachefile}  ;then\
             echo \$(ps1_showUnsync \${cachefile} );\
            else echo \$(ps1_showPush);\
            fi )\
          '${CUSTOM} \$ ')";

fi
PS1="${PS1}"' '

}
########################################################################## 
#gitCacheEnable
gitCacheDisable
