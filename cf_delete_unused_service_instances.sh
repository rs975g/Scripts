#!/bin/bash
# Script to delete unused service instances in a space
#
# **Note** : ensure you are logged into CF and in the 
#            correct Org and Space before running this script.
#
# Usage: ./cf_delete_unused_service_instances.sh
#

ORG=$(cf t | grep "Org" | awk '{print $2}')
SPACE=$(cf t | grep "Space" | awk '{print $2}')
SGUID=$(cf space ${SPACE} --guid)

echo
echo "You are in Org: ${ORG} Space: ${SPACE}"
echo "Are you sure you are to delete?"
echo
echo -n "Type yes to proceed: "
read CONFIRM
echo

if [ $CONFIRM != "yes" ]; then
    echo "Aborting script"
    exit 1
fi

for i in $(cf curl /v2/spaces/${SGUID}/summary?results-per-page=100 | jq -r '.services[]|"\(.name);\(.bound_app_count)"'); do
    SERVICE=$(echo $i | awk -F";" '{print $1}')
    COUNT=$(echo $i | awk -F";" '{print $2}')
    if [ $COUNT -eq 0 ]; then
        echo "Deleting $SERVICE $COUNT"
        cf ds ${SERVICE} -f
    fi
done
