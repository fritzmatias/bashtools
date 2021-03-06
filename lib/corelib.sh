#! /bin/bash
# version: v0.5 
# creator by Matias Fritz
## Deploy script for environment
#set -f #disables the * autocomplet

[ "$LOGLEVEL"x = x ] && export LOGLEVEL=info 
[ "$LOGSTACK"x = x ] && export LOGSTACK=false 
[ "$DEBUG"x != x ] && [ "$DEBUG" = true ] && export LOGLEVEL=debug 
[ "$INFO"x != x ] && [ "$INFO" = true ] && export LOGLEVEL=info
[ "$WARN"x != x ] && [ "$WARN" = true ] && export LOGLEVEL=warn

. colorslib.sh 

enableLogStack(){
  LOGSTACK=true
  warn "LOGSTACK set to $LOGSTACK"
}; 
disableLogStack(){
  LOGSTACK=false
  warn "LOGSTACK set to $LOGSTACK"
}; 

__format(){
local params=$(isDebug && echo "$(__escapebash $@)" || echo $@) 
	[ "$DEBUG_ESCAPEBASH" = "true" ] && echo "__escapebash: $(__escapebash ${params})">&2
	uname | grep 'Darwin' >/dev/null 2>&1 &&  printf "$@\n" \
    || ([ "$(__escapebash $@)"x = x ] \
		&& echo -ne "$params" \
		|| echo -e "$params") 
}; 


__escapebash(){
local data="$@"
local escapePattern='s/\([\\$\/ "\;\*]\)/\\\1/g ;s/\[/\\\[/g ;s/\]/\\\]/g ;s/'"'"'/\\'"'"'/g'
[ "$data"x = x ] \
	&& sed -e "${escapePattern}" \
	|| echo "$data" | sed -e "${escapePattern}" \
	| sed -e "${escapePattern}" 
}; 

testescape(){
	v='/';e='\\\/'
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
	v='\';e='\\\\'
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
	v=';';e='\\\;'
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
	v='[';e='\\\['
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
	v=']';e='\\\]'
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
	v='$';e='\\\$'
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
	v="'";e='\\\'"'"
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
	v='"';e='\\\"'
	a=$(__escapebash "$v") \
		&& [ "$a" = "$e" ] \
		&& [ $(echo $a| wc -c) -eq $(echo $e|wc -c) ] \
		&& info escaping $v '->' $a '('$(echo $a| wc -c)'|'$(echo $e|wc -c)')' ok \
		|| error escaping $v - $a = $e
};

tracelogEnabled(){
	LOGLEVEL="trace" 
};
isTracelog(){
	[ "$LOGLEVEL" = "trace" ] 
};

tracelog(){
local stack=${FUNCNAME[*]}
local filename=$(basename ${BASH_SOURCE[0]} 2>/dev/null||echo source)
	isTracelog \
	&& __format "${darkgray}[TRACE: ${FUNCNAME[1]} ]: $@   $([ $LOGSTACK = true ] && echo -- [STACK] ${stack// /:} )${default}" >&2
        return 0
};
tracelog "Is enabled"

debugEnabled(){
	LOGLEVEL="debug" 
};
isDebug(){
	[ "$LOGLEVEL" = "debug" ] || [ "DEBUG" = "true" ]
};

debug(){
local stack=${FUNCNAME[*]}
local filename=$(basename ${BASH_SOURCE[0]} 2>/dev/null||echo source)
	(isDebug \
        || [ "$LOGLEVEL" = "trace" ]) \
	&& __format "${darkgray}[DEBUG: ${FUNCNAME[1]} ]: $@   $([ $LOGSTACK = true ] && echo -- [STACK] ${stack// /:} )${default}" >&2
        return 0
};

debug "Is enabled"

info(){
local stack=${FUNCNAME[*]}
        (isDebug\
        || [ "$LOGLEVEL" = "trace" ] \
	|| [ "$LOGLEVEL" = "info" ]) \
	&& __format "${cyan}[INFO: ${FUNCNAME[1]} ]: $@   ${darkgray}$([ "$LOGSTACK" = true ] && echo -- [STACK] ${stack// /:} )${default}" >&2
        return 0
};

warn(){
local stack=${FUNCNAME[*]}
        ( isDebug \
        || [ "$LOGLEVEL" = "trace" ] \
        || [ "$LOGLEVEL" = "info" ] \
        || [ "$LOGLEVEL" = "warn" ]) \
	&& __format "${yellow}[WARN: ${FUNCNAME[1]} ]: $@  ${darkgray}$([ "$LOGSTACK" = true ] && echo -- [STACK] ${stack// /:} )${default}" >&2
        return 0
};

error(){
local err=$1; 
local stack=${FUNCNAME[*]}
local re='^-?[0-9]+$'

	[[ $err =~ $re ]] && shift || err=1
    __format "${red}[ERROR: ${FUNCNAME[1]} ] $@  ${darkgray}([STACK] ${stack// /:})${default}" >&2
    return $err
};

fatal(){
local err=$1;
local stack=${FUNCNAME[*]}
local re='^-?[0-9]+$'

	[[ $err =~ $re ]] && shift || err=1
        __format "${red}[FATAL: ${FUNCNAME[1]} ] Exit $err - $@ ${darkgray} ([STACK] ${stack// /:})${default}" >&2
        exec $SHELL
};

require(){
local params;
        tracelog "required params: $@"
        for tst in $@; do
            tracelog $tst: $(eval echo \"\$\{$tst\}\")
            [ "$(eval echo \$$tst)x" = "x" ] && params="$params $tst" && error "${FUNCNAME[1]}:required '$tst' but is undefined"\
	    || debug "[ ${FUNCNAME[1]} ]: $tst=$(eval echo \$$tst)"
        done
        ([ "${#@}" -gt 0 ] && [ "${#params}" -eq 0 ] && tracelog "${FUNCNAME[1]}:All requirements satisfied") \
            || fatal 1 "${FUNCNAME[1]}:require parameters '$@'" 
};

assert(){
local cmd=$@
    require cmd
    set -f
    eval "${cmd}" || fatal 1 "${FUNCNAME[1]}: Assertion error trying to execute: $@"
    local result=$?
    set +f
    return $result
}; 

testlog(){
	debug debug message
 	info info message
	warn warn message
	error error message
	bash -c 'fatal 3 fatal message from terminal'
	bash -c 'error 3 fatal message from terminal'
	bash -c 'warn warn message from terminal'
	bash -c 'info info message from terminal'
	bash -c 'debug debug message from terminal'
	return 0
};

functionsOf(){
local file=$1
require file 
	grep '[a-zA-Z][a-zA-Z0-9]*(){' "$file" |sed -e 's/(){//g'
};

exportf(){
local file=$1
require file 

	file=find $(echo $PATH|sed -e 's:/:/ /g' ) -name "$file" || error "$file not found on $PATH"
	require file
	source "$file"
	for funcName in $(grep '[a-zA-Z][a-zA-Z0-9]*(){' "$file" |sed -e 's/(){//g');do
		eval 
	done
}; 

import(){
local file=$1
#local filename=$(basename "$file")
#local filename="${filename/ /}"
#local importedFile="IMPORTED_${filename%%.sh}"
#require file filename importedFile
require file 

local filepath=$(IFS=':';for path in $PATH; do find $path -name $file 2>/dev/null;done|sort -u)
local pathcount=$(echo $filepath|wc -l) 

	[ "$pathcount" -gt 1 ] && fatal 1 "Multiple paths importing $file ($pathcount: $filepath)"
	source $filepath && debug "$filepath imported on process ($$)" || fatal 2 "Can't import $file from $filepath"

#	[ $(eval echo '"$'${importedFile}'"')x = x ] \
#	&& source $filepath && debug "$filepath imported" \
#	&& eval export ${importedFile}=info && info "'$file' imported" || fatal 2 "Can't import $file from $filepath"

}; 

foreach(){
  debug "foreach param: $@"
  if [ "${1}" = "help" -o "${1}" = "-h" -o "${1}" = "--help" ]; then
	cat <<-EOF 
		Does a foreach directory -1 level deep- and runs it.
		A self repository name replacement is going to be done with {}.
		i.e. foreach dir1 file1 -- 'basename {}' is going to print each directory name.
		i.e. foreach 'echo dir1 file2 | basename {} ' is going to print each directory name.
		i.e. foreach '[ -f "{}/pom.xml" ] && echo {} is java repo' is going to print those repos who as pom.xml.
	EOF
	return 1
  fi
  #for repo in $(find . -type d -maxdepth 1 -mindepth 1|sed -e 's/\.\///g'|sort); do 
	local list;
	local cmd;
	local listPopulated="false"
	if echo "$@" | grep -e '.* -- .*' ; then
		for param in $@; do
			require param 
			if [ "$param" = "--" ]; then
				listPopulated="true"
			else
				if [ "$listPopulated" = "false" ]; then
					list="$list $param"
				else
					cmd="$cmd $param "
				fi
			fi
		done
	else 
		cmd="$@"
		list=$(</dev/stdin)
	fi
  require list cmd
  for repo in ${list}; do
    debug "repo: $repo $(echo $(echo ${repo}|__escapebash))"
  	local cmdToRun="$(echo ${cmd} | sed -e 's/{}/'"$(echo ${repo}|__escapebash)"'/g;s/\\{\\}/{}/g')";
	debug "Going to run '$cmdToRun' on '${repo}'"
  	local output=$(eval "$(echo ${cmdToRun})");
	local result=$?
  	#eval "$(echo ${cmd} | sed -e 's/{}/'$repo'/g')";
	  if [ $result -ne 0 ]; then
	  	warn "'$cmdToRun' ($result): $output"
	  else
		echo -e "${output}"
      fi
  done |grep -v '^$'
}; 

debug "Imported coreLib" 
