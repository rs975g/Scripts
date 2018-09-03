#!/bin/bash
echo "Do you want memory usage for particular org ? y/n"
read option
if [ $option = "y" ]
then
  #memory usage for individual org.
  echo "If the org name contains spaces give it in + format (unicode)"
  echo -n "enter org name> "
  read orgname
  echo "getting org usage ..."
  myorg=$(cf curl /v2/organizations?q=name:$orgname)
  orginf=$(echo $myorg | jq -r ".resources[].metadata.guid")
  qut_lmt_raw=$(echo $myorg | jq -r ".resources[].entity.quota_definition_guid")
  mem_org=$(cf curl /v2/organizations/$orginf/memory_usage | jq -r ".memory_usage_in_mb")
  App_org=$(cf curl /v2/organizations/$orginf/instance_usage | jq -r ".instance_usage")
  mem_lmt_raw=$(cf curl /v2/quota_definitions/$qut_lmt_raw | jq -r ".entity.memory_limit")
  inst_org_full=$(cf curl /v2/quota_definitions/$qut_lmt_raw | jq -r ".entity.total_services")
  plan_org=$(cf curl /v2/quota_definitions/$qut_lmt_raw | jq -r ".entity.name")
  inst_org_raw=$(cf curl /v2/organizations/$orginf/summary | jq -r .spaces[].service_count)
  sum=0; for i in $inst_org_raw; do ((sum += i)); done;
  echo "$orgname is $mem_org MB of $mem_lmt_raw MB and $sum instances active of $inst_org_full: $plan_org ::App count $App_org"
  exit 0

elif [ $option = "n" ]; then
PAGE=1
LAST_PAGE=0

while [ $LAST_PAGE -eq 0 ]
do
	ORG_JSON=$(cf curl "/v2/organizations?order-direction=asc&page=$PAGE&results-per-page=50")

	GUIDS_RAW=$(echo $ORG_JSON | jq -r ".resources[].metadata.guid")
	NAMES_RAW=$(echo $ORG_JSON | jq -r ".resources[].entity.name")
	QUOTA_URLS_RAW=$(echo $ORG_JSON | jq -r ".resources[].entity.quota_definition_url")
	STATUS_RAW=$(echo $ORG_JSON | jq -r ".resources[].entity.status")

	OIFS=$IFS
	IFS=$'\n' read -rd ' ' -a GUIDS <<< "$GUIDS_RAW"
	IFS=$'\n' read -rd ' ' -a NAMES <<< "$NAMES_RAW"
	IFS=$'\n' read -rd ' ' -a QUOTA_URLS <<< "$QUOTA_URLS_RAW"
	IFS=$'\n' read -rd ' ' -a STATUS <<< "$STATUS_RAW"
	IFS=$OIFS

	INDEX=0
	while [ $INDEX -lt ${#GUIDS[@]} ]
	do
		#There are big chunks of results with no names... being paranoid and checking:
		if [ -z ${NAMES[$INDEX]} ]; then
			NAMES[$INDEX]=$(cf curl "/v2/organizations/${GUIDS[$INDEX]}/summary" | jq -r ".name")
		fi
		MEM_UTIL=$(cf curl "/v2/organizations/${GUIDS[$INDEX]}/memory_usage" | jq -r ".memory_usage_in_mb")
		QUOTA_MEM=$(cf curl ${QUOTA_URLS[$INDEX]} | jq -r ".entity.memory_limit")
    ORG_PLN=$(cf curl ${QUOTA_URLS[$INDEX]} | jq -r ".entity.name")
    INST_UTIL=$(cf curl "/v2/organizations/${GUIDS[$INDEX]}/instance_usage" | jq -r ".instance_usage")
    INST_PLN=$(cf curl ${QUOTA_URLS[$INDEX]} | jq -r ".entity.total_services")
    echo "${NAMES[$INDEX]}::$MEM_UTIL MB of $QUOTA_MEM MB & $INST_UTIL of $INST_PLN @ $ORG_PLN::${STATUS[$INDEX]}"
		#echo "Orgguid-${GUIDS[$INDEX]} orgname- ${NAMES[$INDEX]} @ $MEM_UTIL MB of $QUOTA_MEM MB: status=${STATUS[$INDEX]}"
    #enable above to get the org guid as well
		let INDEX=INDEX+1
	done

	NEXT_PAGE_URL=$(echo $ORG_JSON | jq -r ".next_url")
	if [ NEXT_PAGE_URL == "null" ]; then
		let LAST_PAGE=1
	fi
	let PAGE=PAGE+1

done
exit 0
else
	echo "enter a valid option and try again "
fi
