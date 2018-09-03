#!/bin/bash

#./DisableQuota_1.sh <org> <env(aws/asv>)

org_guid="$(cf curl /v2/organizations?q=name\:"$1" | jq -r ".resources[].metadata.guid")"
echo XXXXXXXXXXXXXXXXXXXX------------------NEW USER-----------------------XXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo $1
echo $org_guid

space_id_raw="$(cf curl /v2/organizations/$org_guid/spaces | jq -r ".resources[].metadata.guid")"
OIFS=$IFS
IFS=$'\n' read -rd ' ' -a space_id <<< "$space_id_raw"
for space_raw in "${space_id[@]}" 
do
	
   apps_guid_raw=$(cf curl /v2/spaces/$space_raw/summary | jq -r ".apps[].guid")
   IFS=$'\n' read -rd ' ' -a apps_guid <<< "$apps_guid_raw"

for application_guid in "${apps_guid[@]}"
do
	service_bindings_raw=$(cf curl /v2/apps/$application_guid/service_bindings | jq -r ".resources[].metadata.guid")
	IFS=$'\n' read -rd ' ' -a service_bindings_guid <<< "$service_bindings_raw"
	for service_binding_guid in "${service_bindings_guid[@]}"
	do
		sb_delete_job=$(cf curl "/v2/service_bindings/$service_binding_guid" -X DELETE)
		echo "deleting service bindings "
		echo $sb_delete_job
		echo "deleting service bindings " >> logs
		echo $sb_delete_job >> logs
	done

	app_name=$(cf curl /v2/apps/$application_guid | jq -r .entity.name)
	echo "app name is " echo $app_name
	echo "deleting app " echo $app_name
	app_delete_job=$(cf curl /v2/apps/$application_guid -X DELETE)
	echo $app_delete_job
done

   service_instances_guid_raw=$(cf curl /v2/spaces/$space_raw/summary | jq -r ".services[].guid")
   IFS=$'\n' read -rd ' ' -a service_instances_guid <<< "$service_instances_guid_raw"

 for instance_guid in "${service_instances_guid[@]}"
 do
  info_req=$(cf curl /v2/service_instances/$instance_guid)
  space_guid=$(echo $info_req | jq -r ".entity.space_guid")
  space_info=$(cf curl /v2/spaces/$space_guid | jq -r ".entity.name")
  echo "Inside space" $space_info
  service_instances_name=$(echo $info_req | jq -r ".entity.name")
  echo "Instace name is " $service_instances_name
  echo "deleting service instance now"
  service_delete_job=$(cf curl /v2/service_instances/$instance_guid?purge=true -X DELETE)
  echo $job

 done
done


IFS=$OIFS

# Disabling quota for org
# this one is for basic env
#cf curl /v2/organizations/$org_guid -d '{"quota_definition_guid":"dfe855dc-2bc5-4627-831a-9434d9a3fbe3"}' -X PUT

#For cancelled - US-West
cf curl /v2/organizations/$org_guid -d '{"quota_definition_guid":"cdd0e73c-0bdc-4749-91ff-ac02b481a1b8"}' -X PUT

# This one is for select
#cf curl /v2/organizations/$org_guid -d '{"quota_definition_guid":"0055de39-9fa7-44e6-be60-257f3828944b"}' -X PUT
#cf curl /v2/organizations/$org_guid -d '{"quota_definition_guid":"785552d8-ecfa-4588-97e9-81d865f6340b"}' -X PUT

#For cancelled - Frankfurt
#cf curl /v2/organizations/$org_guid -d '{"quota_definition_guid":"822c85e0-db9f-4a7c-9449-a579ebc9478e"}' -X PUT

#For Japan

#cf curl /v2/organizations/$org_guid -d '{"quota_definition_guid":"6247292f-a4f3-4bd8-ad2a-ea37b76c6686"}' -X PUT

#nurego Call

account_id="$(curl -s -X GET "https://api.nurego.com/v1/organizations/$org_guid?api_key=lec3f53c-4cee-4500-b692-04036cd86e64" | jq -r ".account_no")"

plat_sub_id="$(curl -s -X GET "https://api.nurego.com/v1/subscriptions/$org_guid?api_key=lec3f53c-4cee-4500-b692-04036cd86e64" | jq -r ".id")"

job_sub_plat="$(curl -s -X DELETE -H "Content-Type: application/json" -d '{"provider": "cloud-foundry"}' "https://api.nurego.com/v1/organizations/$org_guid/subscriptions/$plat_sub_id?api_key=lec3f53c-4cee-4500-b692-04036cd86e64")"

job_cancel_account=$(curl -s -X DELETE -H "Content-Type: application/json" "https://api.nurego.com/v1/accounts/$account_id?api_key=lec3f53c-4cee-4500-b692-04036cd86e64")

echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo $account_id
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo $plat_sub_id
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo $job_sub_plat
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo $job_cancel_account

echo XXXXXXXXXXXXXXXXXXXX------------------END USER-----------------------XXXXXXXXXXXXXXXXXXXXXXXXXXXX
echo XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX



