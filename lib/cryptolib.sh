#!/bin/bash

. corelib.sh

function p12tojks(){
local p12file="$1"
local jksfile="$2"
local p12alias="$3"
local jksalias="$4"
[ "$p12alias"x = x ] \
	&& warn "Searching alias on $p12file" \
	&&  p12alias=$(keytool -v -list -storetype pkcs12 -keystore storage-service.oliver-assured-am-staging.p12 | grep 'Alias name:' | cut -d' ' -f3)\
       	&& jksalias=$p12alias
require p12file jksfile p12alias jksalias

	keytool -importkeystore -srckeystore "$p12file" -srcstoretype pkcs12 -srcalias "$p12alias" \
 -destkeystore "$jksfile" -deststoretype jks -destalias "$jksalias"
}; #export -f p12tojks
