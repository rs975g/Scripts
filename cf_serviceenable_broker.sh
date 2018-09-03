#!/bin/sh

#if you have a broker name using this script is easy
#give the broker name
#give the org name 
broker_name=()
org_name=()
#if the org name contains space give it in """org name """
OIFS=$IFS
for broker in "${broker_name[@]}";
do

broker_guid=$(cf curl /v2/service_brokers?q=name:"$broker" | jq -r '.resources[].metadata.guid')
service_guid=$(cf curl /v2/services?q=service_broker_guid:"$broker_guid" | jq -r '.resources[].metadata.guid')
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
echo " Added $broker to $name "
echo "--------------------------"
done
done
done
