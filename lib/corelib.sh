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
local escapePattern='s/\([\\$ "\;\*]\)/\\\1/g;s/\[/\\\[/g;s/\]/\\\]/g;s/'"'"'/\\'"'"'/g'
[ "$data"x = x ] \
	&& sed -e "${escapePattern}" \
	|| echo "$data" | sed -e "${escapePattern}" \
	| sed -e "${escapePattern}" 
}; 

testescape(){
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

isDebug(){
	[ "$LOGLEVEL" = "debug" ] || [ "DEBUG" = "true" ]
};

debug(){
local stack=${FUNCNAME[*]}
local filename=$(basename ${BASH_SOURCE[0]} 2>/dev/null||echo source)
	isDebug \
	&& __format "${darkgray}[DEBUG: ${FUNCNAME[1]} ]: $@   $([ $LOGSTACK = true ] && echo -- [STACK] ${stack// /:} )${default}" >&2
        return 0
};

debug "Is enabled"

info(){
local stack=${FUNCNAME[*]}
        (isDebug || [ "$LOGLEVEL" = "info" ]) \
	&& __format "${cyan}[INFO: ${FUNCNAME[1]} ]: $@   ${darkgray}$([ "$LOGSTACK" = true ] && echo -- [STACK] ${stack// /:} )${default}" >&2
        return 0
};

warn(){
local stack=${FUNCNAME[*]}
        ( isDebug \
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
        debug "required params: $@"
        for tst in $@; do
            debug $tst:$(eval echo \"\$\{$tst\}\")
            [ "$(eval echo \$$tst)x" = "x" ] && params="$params $tst" && error "${FUNCNAME[1]}:required '$tst' but is undefined" || debug "Requirement ${FUNCNAME[1]}: $tst, satisfied as: $(eval echo \$$tst)"
        done
        ([ "${#@}" -gt 0 ] && [ "${#params}" -eq 0 ] && debug "${FUNCNAME[1]}:All requirements satisfied") \
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
local cmd="$@"
  for repo in $(ls -1); do 
  	eval "$(echo $cmd | sed -e 's/{}/'$repo'/g')";
  done;
}; 

debug "Imported coreLib" 
