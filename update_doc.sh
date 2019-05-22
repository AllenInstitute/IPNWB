#!/bin/bash

# Requires:
# - url: https://stedolan.github.io/jq/
#   cmd: ▶ wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ~/.local/bin/jq
#   version: >=1.6
# - url: https://github.com/kislyuk/yq
#   cmd: ▶ pip3 install --user yq
#   version: 2.10.0
# - url: https://github.com/drbild/json2yaml
#   cmd: ▶ pip3 install --user json2yaml
#   version: 1.1.1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mkdir -p ${DIR}/doc
logfile=${DIR}/doc/schema.diff
jqargs='walk(if type == "object" and has("required") then select(.required != false) else . end)'

echo > $logfile
git submodule status | tee --append $logfile
echo >> $logfile

for compare in ${DIR}/nwb.*.json
do
	compare=${compare##*/}
	compare=${compare%.*}
	file1=$(mktemp --dry-run --suffix=.json --tmpdir ${compare}.nwb.XXXXXXXXXX)
	yq . ${DIR}/specifications/core/${compare}.yaml | jq -S . | jq "$jqargs" | tee $file1 >/dev/null
	file2=$(mktemp --dry-run --suffix=.json --tmpdir ${compare}.ipnwb.XXXXXXXXXX)
	jq "$jqargs" ${DIR}/${compare}.json | tee $file2 >/dev/null

	echo "# diff NWB vs IPNWB specifications for $compare" | tee --append $logfile
	echo "$file1 $file2"
	diff $file1 $file2 >> $logfile
	echo >> $logfile
	diff --color $file1 $file2

	jq -S . "${DIR}/${compare}.json" > $file2
	#meld $file1 $file2
	jq -cS . "$file2" > "${DIR}/${compare}.json"

	json2yaml ${DIR}/${compare}.json  | yq -y --indentless-lists . > ${DIR}/doc/${compare}.yaml
done
