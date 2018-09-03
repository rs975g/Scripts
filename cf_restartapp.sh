#!/bin/bash
SPACE_GUID=$(cf curl "/v2/routes?q=host:$1" | jq -r ".resources[].entity.space_guid")
SPACE_INFO=$(cf curl "/v2/spaces/$SPACE_GUID")
SPACE_NAME=$(echo $SPACE_INFO | jq -r ".entity.name")
ORG_GUID=$(echo $SPACE_INFO | jq -r ".entity.organization_guid")
ORG_NAME=$(cf curl /v2/organizations/$ORG_GUID | jq -r ".entity.name")
echo "App Name: " $1
echo "Org Name: " $ORG_NAME
echo "Space Name: " $SPACE_NAME
echo ""
echo "what do you wanna do with app -restart/restage/stop/start/delete?"
read option
if [ $option = "stop" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf stop $1
  exit 0
elif [ $option = "restage" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf restage $1
  exit 0
elif [ $option = "restart" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf restart $1
  exit 0
elif [ $option = "start" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf start $1
  exit 0
elif [ $option = "delete" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf delete $1
	exit 0
else
	echo "please enter a valid option and try again"
fi
