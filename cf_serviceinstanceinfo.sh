#!/bin/bash
#this script finds the service instances info for the platform
#inputs are the service name

echo "enter the service name?"
read option
service_info=$(cf curl /v2/services?q=label:$option)
service_plan_url=$(echo $service_info | jq -r .resources[].entity.service_plans_url)
service_plan_info=$(cf curl $service_plan_url)
service_plan_name=$(echo $service_plan_info | jq -r .resources[].entity.name )
echo "Available plans for $option are $service_plan_name. // which plan you want info for ?"
read plan
PLAN_GUIDS=$(echo $service_plan_info | jq -r '.resources[]| select(.entity.name=="'"$plan"'") | .metadata.guid')
echo "Getting info for plan $plan of $option..."
total_results=$(cf curl "/v2/service_plans/$PLAN_GUIDS/service_instances" | jq -r ".total_results")
echo "Total = $total_results"
echo "@Org || @Space || @Instancename "
echo "----------------------------------"
PAGE=1
LAST_PAGE=0
while [ $LAST_PAGE -eq 0 ]
do
    instances_JSON=$(cf curl "/v2/service_plans/$PLAN_GUIDS/service_instances?order-direction=asc&page=$PAGE&results-per-page=50")
    TEMP_ARRAY_RAW=$(echo $instances_JSON | jq -r ".resources[].metadata.guid")
	#TEMP_ARRAY_RAW=$(cf curl "/v2/service_plans/$PLAN_GUID/service_instances" | jq -r ".resources[].metadata.guid")
    OIFS=$IFS
	IFS=$'\n' read -rd ' ' -a SERVICE_INSTANCE_GUIDS <<< "$TEMP_ARRAY_RAW"
	IFS=$OIFS
	#SERVICE_INSTANCE_GUIDS=("${SERVICE_INSTANCE_GUIDS[@]}" "${TEMP_ARRAY[@]}")
	INDEX=0
	while [ $INDEX -lt ${#SERVICE_INSTANCE_GUIDS[@]} ]
	do
      #for INSTANCE_GUID in "${SERVICE_INSTANCE_GUIDS[@]}"
      #do
        instance_info=$(cf curl /v2/service_instances/${SERVICE_INSTANCE_GUIDS[$INDEX]})
	    INSTANCE_NAME=$(echo "$instance_info" | jq -r ".entity.name")
	    INSTANCE_SPACE_GUID=$(echo "$instance_info" | jq -r ".entity.space_guid")
        space_info=$(cf curl /v2/spaces/$INSTANCE_SPACE_GUID)
	    INSTANCE_SPACE_NAME=$(echo "$space_info" | jq -r ".entity.name")
	    INSTANCE_ORG_GUID=$(echo "$space_info" | jq -r ".entity.organization_guid")
	    INSTANCE_ORG_NAME=$(cf curl "/v2/organizations/$INSTANCE_ORG_GUID" | jq -r ".entity.name")
        echo "$INSTANCE_ORG_NAME || $INSTANCE_SPACE_NAME || $INSTANCE_NAME "
      let INDEX=INDEX+1
    done

    NEXT_PAGE_URL=$(echo $instances_JSON | jq -r ".next_url")
	if [ NEXT_PAGE_URL == "null" ]; then
		let LAST_PAGE=1
	fi
	let PAGE=PAGE+1
done
exit 0
