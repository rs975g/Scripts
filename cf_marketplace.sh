#!/bin/sh
#T find out the services in marketplace
#echo -n "Enter org name  > "
#read org
OIFS=$IFS
orgs_guids=$(cf org "$1" --guid)
echo "Getting services in $1 ......"
space_names_raw=$(cf curl /v2/organizations/$orgs_guids/spaces | jq -r '.resources[] .metadata.guid')
IFS=$'\n' read -rd ' ' -a space_names <<< "$space_names_raw"
for space in "${space_names[@]}"
do
cf curl /v2/spaces/$space/services | jq -r '.resources[] .entity.label'
echo "-----------------"
break 1
done
