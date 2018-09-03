#!/bin/bash
#app should have a route binded to it. 
#takes in the list value 
#save a file with all the app names in name.txt
app_list_raw=$(cat name.txt)
OIFS=$IFS
  IFS=$'\n' read -rd ' ' -a app_list <<< "$app_list_raw"
  IFS=$OIFS
for app in "${app_list[@]}";
do
SPACE_GUID=$(cf curl "/v2/routes?q=host:$app" | jq -r ".resources[].entity.space_guid")
SPACE_INFO=$(cf curl "/v2/spaces/$SPACE_GUID")
SPACE_NAME=$(echo $SPACE_INFO | jq -r ".entity.name")
ORG_GUID=$(echo $SPACE_INFO | jq -r ".entity.organization_guid")
ORG_NAME=$(cf curl /v2/organizations/$ORG_GUID | jq -r ".entity.name")
echo "App Name: " $app
echo "Org Name: " $ORG_NAME
echo "Space Name: " $SPACE_NAME
echo ""
echo "what do you wanna do with app -restart/restage/stop/start/delete?"
read option
if [ $option = "stop" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf stop $app
elif [ $option = "restage" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf restage $app
elif [ $option = "restart" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf restart $app
elif [ $option = "start" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf start $app
elif [ $option = "delete" ]
then
	cf t -o $ORG_NAME -s $SPACE_NAME
  cf delete $app
else
	echo "please enter a valid option and try again"
fi
done

