#!/bin/bash
 
#SERVICE_GUID=$(cf curl "/v2/services?q=label:$1" | jq -r ".resources[].metadata.guid")
#SERVICE_PLANS_RAW=$(cf curl "/v2/service_plans?q=service_guid:$SERVICE_GUID" | jq -r ".resources[].metadata.guid")
echo $1
PLAN_GUIDS_RAW=$(cf curl "/v2/service_plans" | jq -r '.resources[] | select(.entity.name=="'"$1"'") | .metadata.guid')
OIFS=$IFS
IFS=$'\n' read -rd ' ' -a PLAN_GUIDS <<< "$PLAN_GUIDS_RAW"

SERVICE_INSTANCE_GUIDS=()

for PLAN_GUID in "${PLAN_GUIDS[@]}"
do
    echo $PLAN_GUID
	TEMP_ARRAY_RAW=$(cf curl "/v2/service_plans/$PLAN_GUID/service_instances" | jq -r ".resources[].metadata.guid")
	IFS=$'\n' read -rd ' ' -a TEMP_ARRAY <<< "$TEMP_ARRAY_RAW"
	#echo "${TEMP_ARRAY[@]}"
	SERVICE_INSTANCE_GUIDS=("${SERVICE_INSTANCE_GUIDS[@]}" "${TEMP_ARRAY[@]}")
done

for INSTANCE_GUID in "${SERVICE_INSTANCE_GUIDS[@]}"
do
	INSTANCE_NAME=$(cf curl "/v2/service_instances/$INSTANCE_GUID" | jq -r ".entity.name")
	INSTANCE_SPACE_GUID=$(cf curl "/v2/service_instances/$INSTANCE_GUID" | jq -r ".entity.space_guid")
	INSTANCE_SPACE_NAME=$(cf curl "/v2/spaces/$INSTANCE_SPACE_GUID" | jq -r ".entity.name")
	
	INSTANCE_ORG_GUID=$(cf curl "/v2/spaces/$INSTANCE_SPACE_GUID" | jq -r ".entity.organization_guid")
	INSTANCE_ORG_NAME=$(cf curl "/v2/organizations/$INSTANCE_ORG_GUID" | jq -r ".entity.name")
	
	INSTANCE_PLAN_GUID=$(cf curl "/v2/service_instances/$INSTANCE_GUID" | jq -r ".entity.service_plan_guid")
	SERVICE_GUID=$(cf curl "/v2/service_plans/$INSTANCE_PLAN_GUID" | jq -r ".entity.service_guid")
	SERVICE_NAME=$(cf curl "/v2/services/$SERVICE_GUID" | jq -r ".entity.label")
	
	echo "--------"
	echo "Service name: " $SERVICE_NAME
	echo "Instance name: " $INSTANCE_NAME
	echo "Org: " $INSTANCE_ORG_NAME
	echo "Space: " $INSTANCE_SPACE_NAME
done
IFS=$OIFS