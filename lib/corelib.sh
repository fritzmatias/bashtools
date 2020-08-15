#! /bin/bash
# version: v0.5 
# creator by Matias Fritz
## Deploy script for environment
set -f #disables the * autocomplet


[ "$LOGLEVEL"x = x ] && export LOGLEVEL=info && info "loglevel set to info" || (debug skip loading the same logging again && exit 0 )
[ "$LOGSTACK"x = x ] && export LOGSTACK=false 
[ "$DEBUG"x != x ] && [ "$DEBUG" = true ] && export LOGLEVEL=debug
[ "$INFO"x != x ] && [ "$INFO" = true ] && export LOGLEVEL=info
[ "$WARN"x != x ] && [ "$WARN" = true ] && export LOGLEVEL=warn


enableLogStack(){
  LOGSTACK=true
  warn "LOGSTACK set to $LOGSTACK"
}; export -f enableLogStack
disableLogStack(){
  LOGSTACK=false
  warn "LOGSTACK set to $LOGSTACK"
}; export -f disableLogStack

debug(){
local stack=${FUNCNAME[*]}
local filename=$(basename ${BASH_SOURCE[0]})
[ "$LOGLEVEL" = "debug" ] && echo "[DEBUG: ${filename}] ${FUNCNAME[1]}: $@  $([ "$LOGSTACK" = true ] && echo -- [STACK] ${stack// /:} )" >&2
        return 0
};export -f debug

info(){
local stack=${FUNCNAME[*]}
local filename=$(basename ${BASH_SOURCE[0]})
        ([ "$LOGLEVEL" = "debug" ] || [ "$LOGLEVEL" = "info" ]) && echo "[INFO: ${filename}] ${FUNCNAME[1]}: $@   $([ "$LOGSTACK" = true ] && echo -- [STACK] ${stack// /:} )" >&2
        return 0
};export -f info

warn(){
local filename=$(basename ${BASH_SOURCE[0]})
local stack=${FUNCNAME[*]}
        ([ "$LOGLEVEL" = "debug" ] \
        || [ "$LOGLEVEL" = "info" ] \
        || [ "$LOGLEVEL" = "warn" ]) \
         && echo "[WARN: ${filename}] ${FUNCNAME[1]}: $@  $([ "$LOGSTACK" = true ] && echo -- [STACK] ${stack// /:} )" >&2
        return 0
};export -f warn

error(){
local err=$1; 
local stack=${FUNCNAME[*]}
local re='^-?[0-9]+$'
local filename=$(basename ${BASH_SOURCE[0]})

	[[ $err =~ $re ]] && shift || err=1
        echo "[ERROR: ${filename}] ${FUNCNAME[-1]}: $@  ([STACK] ${stack// /:})" >&2
        return $err
};export -f error

fatal(){
local err=$1;
local stack=${FUNCNAME[*]}
local re='^-?[0-9]+$'
local filename=$(basename ${BASH_SOURCE[0]})

	[[ $err =~ $re ]] && shift || err=1
        echo "[FATAL: ${filename}] ${FUNCNAME[-1]}: Exit $err - $@ ([STACK] ${stack// /:})" >&2
        exit $err
};export -f fatal

require(){
local params;
        debug "required params: $@"
        for tst in $@; do
            debug $tst:$(eval echo \"\$\{$tst\}\")
            [ "$(eval echo \$$tst)x" = "x" ] && params="$params $tst" && error "${FUNCNAME[1]}:required '$tst' but is undefined" || debug "Requirement ${FUNCNAME[1]}: $tst, satisfied as: $(eval echo \$$tst)"
        done
        ([ "${#@}" -gt 0 ] && [ "${#params}" -eq 0 ] && debug "${FUNCNAME[1]}:All requirements satisfied") \
            || fatal 1 "${FUNCNAME[1]}:require parameters '$@'" 
};export -f require

assert(){
local cmd=$@
    require cmd
    eval "${cmd}" || fatal 1 "${FUNCNAME[1]}: Assertion error trying to execute: $@"
}; export -f assert

testlog(){
	debug debug message
 	info info message
	warn warn message
	error error message
	warn fatal message is not tested
};export -f testlog

functionsOf(){
local file=$1
require file 
	grep '[a-zA-Z][a-zA-Z0-9]*(){' "$file" |sed -e 's/(){//g'
};export -f functionsOf

exportf(){
local file=$1
require file 

	source "$file"
	for funcName in $(grep '[a-zA-Z][a-zA-Z0-9]*(){' "$file" |sed -e 's/(){//g');do
		eval export -f ${funcName}
	done
}; export -f  exportf

import(){
local file=$1
local filename=$(basename "$file")
local filename="${filename/ /}"
local importedFile="IMPORTED_${filename%%.sh}"
require file filename importedFile

[ $(eval echo '"$'${importedFile}'"')x = x ] && exportf $file && eval export ${importedFile}=info && debug "$file imported" || (debug skip loading logging $file again && exit 0 )
}; export -f import 

