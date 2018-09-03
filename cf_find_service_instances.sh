#!/bin/bash

#when you have the list of service instance and need to know the  space and org name
#takes the input of service_instances
service_instances_guid=()
echo "getting instance info...."
echo "instance :service_instances_name is in space_name of org_name :: plan_name @@ users"
echo "------------------------"
for instance in "${service_instances_guid[@]}";
do
service_instances_info=$(cf curl /v2/service_instances/$instance)
service_instances_name=$(echo $service_instances_info | jq -r .entity.name)
space_url=$(echo $service_instances_info | jq -r .entity.space_url)
space_info=$(cf curl $space_url)
space_name=$(echo $space_info | jq -r .entity.name)
org_info=$(echo $space_info | jq -r .entity.organization_url)
oinfo=$(cf curl $org_info)
org_name=$(echo $oinfo | jq -r .entity.name)
org_users=$(echo $oinfo | jq -r .entity.managers_url)
onames=$(cf curl $org_users | jq -r .resources[].entity.username)
service_plan_info=$(echo $service_instances_info | jq -r .entity.service_plan_url)
plan_name=$(cf curl $service_plan_info | jq -r .entity.name)
echo "$instance :$service_instances_name is in $space_name of $org_name :: $plan_name @@ $onames"
done
