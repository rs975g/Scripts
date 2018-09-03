#!/bin/sh

#get the org guid first
#give the service in service_name()
#give the org name in org_name()
#if the service name is given, use this script

service_name=()
org_name=()
#if the org name contains space give it in """org name """
OIFS=$IFS
for service in "${service_name[@]}";
 do
     service_guid=$(cf curl /v2/services?q=label:"$service" | jq -r '.resources[] | .metadata.guid')
     service_plans_raw=$(cf curl /v2/service_plans?q=service_guid:"$service_guid" | jq -r '.resources[].metadata.guid')
     IFS=$'\n' read -rd ' ' -a service_plans <<< "$service_plans_raw"
done
for name in "${org_name[@]}";
do
   org_guid=$(cf org "$org_name" --guid)

for org  in "${org_guid[@]}";
do

   for plan in "${service_plans[@]}";
   do
    cf curl /v2/service_plan_visibilities -X POST -d '{ "service_plan_guid": "'"$plan"'", "organization_guid":"'"$org"'"}'
   echo " Added $service to $name "
   echo "--------------------------"
 done
 done
done
