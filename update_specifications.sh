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

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
mkdir -p ${DIR}/doc
mkdir -p ${DIR}/namespace/{core,hdmf-common,ndx-mies}/{json,yaml}
logfile=${DIR}/doc/schema.diff
jqargs='--sort-keys --compact-output'

# copy the YAML files into our repo
cp ${DIR}/specifications/core/*.yaml ${DIR}/namespace/core/yaml
cp ${DIR}/specifications/hdmf-common-schema/common/*.yaml ${DIR}/namespace/hdmf-common/yaml
cp ${DIR}/ndx-mies/spec/*.extensions.yaml ${DIR}/namespace/ndx-mies/yaml

# (optional) jqfilters:
#
# jqfilter to remove ".yaml" from namespace specifications:
jqfilter="walk(if type == \"object\" and has(\"source\") then .[] |= rtrimstr(\".yaml\") else . end)"
yq --output-format json '.' specifications/core/nwb.namespace.yaml | jq "$jqfilter" | json2yaml | d2u > namespace/core/yaml/nwb.namespace.yaml
yq  --output-format json '.' specifications/hdmf-common-schema/common/namespace.yaml | jq "$jqfilter" | json2yaml | d2u > namespace/hdmf-common/yaml/namespace.yaml
yq  --output-format json '.' ndx-mies/spec/ndx-mies.namespace.yaml | jq "$jqfilter" | json2yaml | d2u > namespace/ndx-mies/yaml/namespace.yaml

# jqfilter to get only required objects:
# ▶ jqfilter='walk(if type == "object" and has("required") then select(.required != false) else . end)'

echo > $logfile
git submodule status | tee --append $logfile
echo >> $logfile

for file in ${DIR}/namespace/{core,hdmf-common,ndx-mies}/yaml/*.yaml
do
	specification=${file##*/}
	specification=${specification%.*}
	namespace=${file##*namespace/}
	namespace=${namespace%/yaml*}

	if [[ "$namespace" == "hdmf-common" ]]; then
		upstream_path="specifications/hdmf-common-schema/common"
	elif [[ "$namespace" == "core" ]]; then
		upstream_path="specifications/core"
	else
		upstream_path="namespace/ndx-MIES/yaml"
	fi

	echo "# diff namespace $namespace upstream vs IPNWB specifications for $specification" | tee --append $logfile
	diff "${DIR}/${upstream_path}/${specification}.yaml" "$file" | tee --append $logfile

	yq --output-format json '.' "$file" | jq $jqargs . > ${DIR}/namespace/${namespace}/json/${specification}.json
done

d2u ${DIR}/namespace/*/json/*.json
