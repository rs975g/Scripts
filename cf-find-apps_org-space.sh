#!/bin/bash

SPACE_GUID_RAW=$(cf curl "/v2/routes?q=host:$1" | jq -r ".resources[].entity.space_guid")
IFS=$'\n' read -rd ' ' -a SPACE_GUID <<< "$SPACE_GUID_RAW"
for guid in "${SPACE_GUID[@]}";
do
SPACE_INFO=$(cf curl "/v2/spaces/$guid")
SPACE_NAME=$(echo $SPACE_INFO | jq -r ".entity.name")
ORG_GUID=$(echo $SPACE_INFO | jq -r ".entity.organization_guid")
ORG_NAME=$(cf curl /v2/organizations/$ORG_GUID | jq -r ".entity.name")
echo "App Name:" $1
echo "Org Name:" $ORG_NAME
echo "Space Name:" $SPACE_NAME
echo "-------------------------"
done
echo "Chase it? y/n"
read chase
if [[ $chase = "y" ]]; then
  cf t -o $ORG_NAME -s $SPACE_NAME
  cf app $1
	exit 0
elif [[ $chase = "n" ]]; then
	echo "exited"
  exit 0
else
	echo "wrong option"
fi
