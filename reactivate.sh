
timestamp="$(date +%H:%M:%S)"

OIFS=$IFS
IFS=$'\n'

#nurego_api_key="$(cat 0-api_key)"
nurego_api_key=lec3f53c-4cee-4500-b692-04036cd86e64
nurego_url_reactivate_org="https://api.nurego.com/v1/accounts"
nurego_url_org="https://api.nurego.com/v1/organizations"

plan_id_free='pla_e81a-a8f5-4914-b67e-655609b99f7c'



cf_org_guid="$(cf curl /v2/organizations?q=name\:"$1" | jq -r ".resources[].metadata.guid")"

cf curl /v2/organizations/$cf_org_guid -d '{"quota_definition_guid":"62fa5bc5-8c81-440c-8a26-dd104cceb4f3"}' -X PUT

#iterating on SUBS......
count=0
#for cf_org_guid in $(cat $1)
#do
	let "count++"

	req_nurego_org="$(curl -s "$nurego_url_org/$cf_org_guid?api_key=$nurego_api_key&provider=cloud-foundry")"
	echo "$req_nurego_org"
	status="$(echo $req_nurego_org | jq -r .status)"
	echo "$status"
	status_reason="$(echo $req_nurego_org | jq -r .status_reason)"
	account_no="$(echo $req_nurego_org | jq -r .account_no)"	

	if [ "$status" == "canceled" ]
		then
		body="{\"organization_id\": \"$cf_org_guid\",\"plan_id\": \"$plan_id_free\"}"
		url="$nurego_url_reactivate_org/$account_no/reactivate?api_key=$nurego_api_key"

		
 		echo "DONE_$count"':'"$cf_org_guid"'|'"$status"'|'"$status_reason"
		echo XXXXXXXXXXXXXXXXXXX >> log_${1}_done
		echo "$count"':'"$cf_org_guid"'|'"$status"'|'"$status_reason" >> log_${1}_done
		echo >> log_${1}_done
		curl -s --request PUT --url "$url" --header 'content-type: application/json' --data "$body" >> log_${1}_done
		echo >> log_${1}_done
		
	else
		echo "$count"':'"$cf_org_guid"'|'"$status"'|'"$status_reason" >> log_${1}_skipped
		echo "SKIPPED_$count"':'"$cf_org_guid"'|'"$status"'|'"$status_reason"

	fi
	
#done
IFS=$OIFS
