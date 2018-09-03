#!/bin/bash
#script to get public and private services in the platform
#Doesnt take anyinput
function getServices() {
  echo "Getting the service list...."
  echo "-------"
  PAGE=1
  LAST_PAGE=0
  while [ $LAST_PAGE -eq 0 ]
  do
    services_json=$(cf curl "/v2/services?order-direction=asc&page=$PAGE&results-per-page=50")
    TEMP_ARRAY_RAW=$(echo "$services_json" | jq -r ".resources[].metadata.guid")
    OIFS=$IFS
    IFS=$'\n' read -rd ' ' -a SERVICE_GUIDS <<< "$TEMP_ARRAY_RAW"
    IFS=$OIFS
    INDEX=0
    while [ $INDEX -lt ${#SERVICE_GUIDS[@]} ]
    do
      service_info=$(cf curl "/v2/services/${SERVICE_GUIDS[$INDEX]}")
      service_name=$(echo "$service_info" | jq -r ".entity.label")
      service_plan_url=$(echo "$service_info" | jq -r ".entity.service_plans_url")
      service_plan_info=$(cf curl "$service_plan_url")
      service_plan_status=$(echo "$service_plan_info" | jq -r ".resources[].entity.public")
      if [[ $service_plan_status == "false" ]]; then
        #service_plan_status=$(echo "$service_plan_info" | jq -r ".resources[].entity.active")
        #if [[$service_plan_status == "false"]]; then
        echo "$service_name"
        getServiceOwners $service_name
      else
        echo "$service_name" >> ~/publicservices.txt
      fi
      ((INDEX++ ))
    done
    NEXT_PAGE_URL=$(echo "$services_json" | jq -r ".next_url")
    if [ "$NEXT_PAGE_URL" == "null" ]; then
    let LAST_PAGE=1
    fi
    ((PAGE++ ))
  done
  exit 0
}

function getServiceOwners() {
service_broker_info=$(cf curl "/v2/services?q=label:$1")
service_broker_guid=$(echo "$service_broker_info" | jq -r ".resources[].entity.service_broker_guid")
broker_url=$(cf curl "/v2/service_brokers/$service_broker_guid" | jq -r ".entity.broker_url")
broker_domain=$(echo "$broker_url" | sed 's/^https:\/\///;s/.run.asv-pr.ice.predix.io//g')
for domain in "${broker_domain[@]}";
do
SPACE_GUID_RAW=$(cf curl "/v2/routes?q=host:$domain" | jq -r ".resources[].entity.space_guid")
IFS=$'\n' read -rd ' ' -a SPACE_GUID <<< "$SPACE_GUID_RAW"
for guid in "${SPACE_GUID[@]}";
do
SPACE_INFO=$(cf curl "/v2/spaces/$guid")
SPACE_NAME=$(echo "$SPACE_INFO" | jq -r ".entity.name")
ORG_GUID=$(echo "$SPACE_INFO" | jq -r ".entity.organization_guid")
org_managers=$(cf curl "/v2/organizations/$ORG_GUID/managers" | jq -r ".resources[].entity.username")
echo "$org_managers"
echo "-----------------"
done
done
}
getServices
