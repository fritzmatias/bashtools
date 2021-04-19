#! /bin/bash
account="prod"
userID=`whoami`
#github_api_v3_access_token=`aws ssm get-parameters --with-decryption --names "/vcis/${account}/app/github/token-${userID}" --query 'Parameters[0].Value' | tr -d '"'`
usage(){
exec cat <<EOF
  automated tool to replace configuration values on json files. (config/env-config.json)
    check <jsonKey> <MatchValue> <newValue> <list of repos> 
    replace <jsonKey> <MatchValue> <newValue> <list of repos> 
    search <MatchJsonKey> <MatchValue> <list of files>
EOF
}


info(){
    echo $(date +%H:%M:%S) $@ >&1
}

error(){
local err=$1;
    echo $err|grep -e '[0-9]\+' && shift 1 || err=1;
    echo $(date +%H:%M:%S) $@ >&2
    return $err
}

checkIfRepoExist(){
#  local access_token=${github_api_v3_access_token}
  local access_token='67e7c9e0aaf2860184dbb96bb82ce0eb2a35c2bc'
  local repo=(${1//\// })
  local ghe_org=${repo[0]}
  local ghe_repo=${repo[1]}
  local ghe_api_v3_url="https://github.platforms.engineering/api/v3/repos/${ghe_org}/${ghe_repo}?access_token="${access_token}

  local cmd="curl --silent -X GET ${ghe_api_v3_url}"
  info "Checking if https://github.platforms.engineering/api/v3/repos/${ghe_org}/${ghe_repo} exists"
  info "$cmd"
  local checkrepo_api_output=$( eval ${cmd})
  if [[ `echo $checkrepo_api_output | jq '.message'` == *"Not Found"* ]]; then
    error 2 "https://github.platforms.engineering/api/v3/repos/${ghe_org}/${ghe_repo} not found"
  fi
}
getConfigFile(){
local repo="$1"
local startWith="$2"
local endsWith="$3"
  (cd "$repo" \
    && find . -name ${startWith}'*'${endsWith}
  ) 
}

gitRepoUpdate(){
  local repo="$1"
  local baseBranch="$2"
    if ! [ -d "$repo" ] ; then
      checkIfRepoExist $repo \
      && gitClone $repo $baseBranch
    else
      gitPull $repo $baseBranch
    fi 

}
gitPull(){
  local repo="$1"
  local checkout="git checkout "
  local cmd="git pull "
  info "Pulling $repo"
  info "$cmd"
  (cd "$repo" \
    && $checkout $branchName \
    && $cmd 
  )
}
gitClone(){
  local repo="$1"
  assert "echo ${repo}|grep '/'"
  local baseBranch="$2"
  require repo baseBranch
  local cmd="git clone git@github.platforms.engineering:${repo}.git $repo"
  local checkout="git checkout "
  info "Clonning $repo"
  info "$cmd"

  $cmd \
  && ( cd $repo && $checkout $baseBranch )
}

gitBranch(){
  local repo=$1
  local branchName=$2
  local baseBranch=$3
  local cmd="git checkout $baseBranch"
  local cmd2="git checkout -b ${branchName}"
  ( cd $repo \
   && info "on $PWD: Branching to $branchName" \
   && info "$cmd && $cmd2" \
   && $cmd \
   && $cmd2
  )
}
jsonMatch(){
  local repo=$1
  local file=$2
  local key=$3
  local matchValue=$4

  (cd $repo \
   && local currentValue=$(jq ${key} ${file} | sed -e 's/[ ]\+//g') \
   && echo "$currentValue" | grep "$matchValue" \
    && info "$repo Matches $key $matchValue on $file" \
    || error 2 "No match found on $repo "
  )
}
jsonUpdateKey(){
  local repo=$1
  local file=$2
  local key=$3
  local matchValue=$4
  local value=$5
  (cd $repo \
  && info "changing $file, $matchValue -> $value" \
  && jq ${key}' = "'${value}'"'  $file > $file.new \
  && mv $file.new $file)
}

gitCommit(){
  local repo=$1
  local file=$2
  local cmd="git commit -m 'parameterUpdated'"

  (cd $repo \
    && info "$cmd" \
    &&  git add $file \
    && $cmd )
}

gitPush(){
  local repo=$1
  local branchName=$2
  local cmd="git push --set-upstream origin $branchName"

  (cd $repo \
    && info "$cmd" \
    &&  $cmd )
  
}

expandJSONKeys(){
local json="${1}"
local root="$2"
local result="$(echo "${json}" |sed -e 's/:[ ]*\({["a-zA-Z0-9+/=\. \/@,:_-]*}\)/:"removedObject"/g')"
local keys=""
echo [debug] newCallExpand >&2
if [ "$json" = "$result" ] ;then
	echo [debug] json:$json result:$result >&2
	echo [debug] json == result TRUE >&2
	for key in $(echo $result|jq -M|cut -d':' -f1|sed -e 's/ /\\\ /g;s/"//g;s/{//g;s/}//g'|egrep -v '^$'|sed -e 's/^[ ]*\([a-zA-Z0-9 \/@_-]\)/'"${root}"'.\1/g');do
		#echo $result|jq -cM $key >/dev/null 2>&1 
		echo $key
	done
else
	for key in $(expandJSONKeys "${result}");do
		echo "[debug] json key($root$key)">&2
		echo "[debug] json key($root$key): $(echo $json|jq -cM '"'"${root}${key}"'"' )" >&2
		hasValue=$(echo "$json"|jq -cM '"'"$root$key"'"') 
		echo "$hasValue" |egrep '{|}'>/dev/null \
		&& expandJSONKeys "'$(echo $json|jq -cM '"'"${root}${key}"'"')'" "${root}${key}" \
		|| echo "$root$key"
	done
fi
}

json2property(){
local file=$1
local filedata=$(cat $file)
for key in $(expandJSONKeys "$(echo "$filedata"|jq -cM)");do
        echo "$key=$(echo "$filedata"|jq '"'$key'"')";
done
}


repoSearch(){
config=DEV; 
value=value-capture-us-east-1-285453578300;
searchKey=BUCKET
poskey=.value;

for file in $(find value-capture/ POD-Inc/ -name 'config.json'); do 
	realKeys=$(grep $searchKey $file|cut -d':' -f1|sort -u |sed -e 's/"//g;s/^[ ]*//g')
	jq -cM . | sed -e 's/:[ ]*\({["a-zA-Z0-9+/=\. ,:_-]*}\)/: "removedObject"/g'|jq
	for key in $realKeys; do
		info using $key
		grep $key $file >/dev/null 2>&1 \
		&& cat $file \
			|jq -cM .${config}.$(grep BUCKET $file\
			|cut -d':' -f1|sort -u |sed -e 's/"//g;s/^[ ]*//g') \
			|grep -e $value >/dev/null 2>&1 && echo $file "-- $config.$(grep $key $file|cut -d':' -f1|sort -u |sed -e 's/"//g;s/^[ ]*//g')" \
		&& cat $file|jq -cM .${config}.$(grep $key $file|cut -d':' -f1|sort -u |sed -e 's/"//g;s/^[ ]*//g')
	done
done 
}

opt=$1;shift
case $opt in
  clone)
	baseBranch='master'
	for repo in $@; do
	      grep -v $repo repos.deprecated.txt >/dev/null 2>&1 \
	      && checkIfRepoExist $repo \
	      && gitClone $repo $baseBranch || error Repo is deprecated or it exist on the fs
	done
	;;
  replace)
    #jsonKeyPath='.PROD.DB_HOST'
    #matchValue='pod.rds.vcis.internal'
    #value='pod-credit.rds.vcis.internal'
    jsonKeyPath=$1; shift
    matchValue=$1;shift
    value=$1; shift
    baseBranch='master'
    branchName="VCT-14473-automatedChangeFor_"${jsonKeyPath}
    fileToCheck="config/env-config.json"
    for repo in $@ ;do
      checkIfRepoExist $repo \
      && gitClone $repo $baseBranch \
      && jsonMatch $repo $fileToCheck $jsonKeyPath $matchValue \
      && gitBranch $repo $branchName $baseBranch \
      && jsonUpdateKey $repo $fileToCheck $jsonKeyPath $matchValue $value \
      && gitCommit $repo $fileToCheck \
      && gitPush $repo $branchName \
      && rm -rf $repo \
      || error 3 "FAIL on repo $repo"
    done
  ;;
  check)
    jsonKeyPath=$1; shift
    matchValue=$1;shift
    fileToCheck="config/env-config.json"
    for repo in $@ ;do
      fileToCheck=$(getConfigFile "" "config.json") \
      && gitRepoUpdate $repo $baseBranch \
      && checkIfRepoExist $repo \
      && gitClone $repo $baseBranch \
      && jsonMatch $repo $fileToCheck $jsonKeyPath $matchValue \
      || error 3 "FAIL on repo $repo"
    done
    ;;

  search)
	repoSearch 
  ;;
  expandJSONKeys)
	expandJSONKeys $(cat $1|jq -cM .) 
  ;;
  json2property)
	json2property $1
  ;;
  *)
    usage
esac
