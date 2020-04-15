#!/bin/bash

set -e

# Convert IPNWB schema specifications for from yaml to json and store the diff
# to the official specifications in the git submodule.
#
# - The yaml files in namespace/*/yaml/nwb.*.yaml are the schema definitions
#   used within IPNWB. They are human-readable redundant alternatives to the
#   json files.  Any changes to the specifications should first happen here.
#   Use this script to update the json files from these specifications.
#
#   The following schema definitions exist:
#   - core
#   - hdmf-common
#
# - The json files in nwb/json/nwb.*.json are the specifications read by Igor
#   Pro. These specifications are stored in the NWB files. Their keys are
#   sorted alphabetically and the JSON string is compressed to omit needless
#   spaces.
# - doc/schema.diff is generated to emphasize the deviations to the official
#   specifications. The diff is generated from the yaml files.

# Requires:
# - url: https://stedolan.github.io/jq/
#   cmd:
#   - ▶ wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ~/.local/bin/jq
#   - ▶ apt install jq
#   version: >=1.6
# - url: https://github.com/kislyuk/yq
#   cmd: ▶ pip3 install --user yq
#   version: 2.10.0
# - url: https://github.com/drbild/json2yaml
#   cmd: ▶ pip3 install --user json2yaml
#   version: 1.1.1

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mkdir -p ${DIR}/doc
mkdir -p ${DIR}/namespace/{core,hdmf-common}/{json,yaml}
logfile=${DIR}/doc/schema.diff
jqargs='--sort-keys --compact-output'

# copy the YAML files into our repo
cp ${DIR}/specifications/core/*.yaml ${DIR}/namespace/core/yaml
cp ${DIR}/specifications/hdmf-common-schema/common/*.yaml ${DIR}/namespace/hdmf-common/yaml

# (optional) jqfilters:
#
# jqfilter to remove ".yaml" from namespace specifications:
jqfilter="walk(if type == \"object\" and has(\"source\") then .[] |= rtrimstr(\".yaml\") else . end)"
yq --tojson r specifications/core/nwb.namespace.yaml | jq "$jqfilter" | json2yaml | d2u > namespace/core/yaml/nwb.namespace.yaml
yq --tojson r specifications/hdmf-common-schema/common/namespace.yaml | jq "$jqfilter" | json2yaml | d2u > namespace/hdmf-common/yaml/namespace.yaml
#
# jqfilter to get only required objects:
# ▶ jqfilter='walk(if type == "object" and has("required") then select(.required != false) else . end)'

echo > $logfile
git submodule status | tee --append $logfile
echo >> $logfile

for file in ${DIR}/namespace/{core,hdmf-common}/yaml/*.yaml
do
	specification=${file##*/}
	specification=${specification%.*}
	namespace=${file##*namespace/}
	namespace=${namespace%/yaml*}

	if [[ "$namespace" == "hdmf-common" ]]; then
		upstream_path="hdmf-common-schema/common"
	else
		upstream_path=$namespace
	fi

	echo "# diff namespace $namespace upstream vs IPNWB specifications for $specification" | tee --append $logfile
	diff "${DIR}/specifications/${upstream_path}/${specification}.yaml" "$file" | tee --append $logfile

	yq --tojson r "$file" | jq $jqargs . > ${DIR}/namespace/${namespace}/json/${specification}.json
done
