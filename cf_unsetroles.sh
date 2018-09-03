#!/bin/sh
#if you have a list of users, whose roles need to be removed. use this
#inputs: users and org name 

predix_users=()
predix_org=()

OIFS=$IFS
for org in "${predix_org[@]}"
do
  orgs_guids=$(cf org "$org" --guid)
  space_names_raw=$(cf curl /v2/organizations/$orgs_guids/spaces | jq -r '.resources[] .entity.name')
  IFS=$'\n' read -rd ' ' -a space_names <<< "$space_names_raw"
for space in "${space_names[@]}"
do
        for i in "${predix_users[@]}"
        do
                cf unset-space-role $i $org $space SpaceAuditor
                cf unset-space-role $i $org $space SpaceManager
                cf unset-space-role $i $org $space SpaceDeveloper
        done
done
done
