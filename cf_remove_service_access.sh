#!/bin/sh
#disabling service access using api
#get the org guid first
#give the service in service_name()
#give the org name in org_name()
#if the service name is given, use this script

service_name_list=()
org_name_list=()
#if the org name contains space give it in """org name """
#can give mulitiple orgs and services  by space
for service_name in "${service_name_list[@]}";
do
  echo "removing $service_name.."
for org_name in "${org_name_list[@]}";
do
org_guid=$(cf curl /v2/organizations?q=name:"$org_name" | jq -r .resources[].metadata.guid)
service_guid=$(cf curl /v2/services?q=label:"$service_name" | jq -r .resources[].metadata.guid)
service_plans_raw=$(cf curl /v2/service_plans?q=service_guid:"$service_guid" | jq -r .resources[].metadata.guid)
#multiple service plans %3B corresponds to ;
IFS=$'\n' read -rd ' ' -a service_plans <<< "$service_plans_raw"
for plan_guid in "${service_plans[@]}";
    do
    visibility_guid=$(cf curl /v2/service_plan_visibilities?q=organization_guid:"$org_guid"%3Bservice_plan_guid:"$plan_guid" | jq -r .resources[].metadata.guid)
    cf curl /v2/service_plan_visibilities/$visibility_guid -X DELETE
    echo "$service_name disabled in $org_name"
  done
done
done
