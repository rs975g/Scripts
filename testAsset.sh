#!/bin/bash 

# This script creates two instances: predix-uaa (Free), predix-asset (Free)
# Create an uaa client, add data to asset inscance and query the data
# Delete the instances created

function error {
  printf "\e[7;49;31;82m $1 \e[0m"
  exit 1
}
target=$(cf t)

# Setting uaa and asset urls based on cf t
if [[ $target == *"FAILED"* ]];
then
  error "FAIL ----> Not logged in to CF, please do \"cf login\""
elif [[ $target == *"https://api.system.aws-usw02-pr.ice.predix.io"* ]];
then
  #echo "It's BASIC!";
  uaaSuffixUrl="predix-uaa.run.aws-usw02-pr.ice.predix.io"
  assetUrl="https://predix-asset.run.aws-usw02-pr.ice.predix.io"
elif [[ $target == *"https://api.system.asv-pr.ice.predix.io"* ]];
then
  #echo "It's SELECT!";
  uaaSuffixUrl="predix-uaa.run.asv-pr.ice.predix.io"
  assetUrl="https://predix-asset.run.asv-pr.ice.predix.io"
elif [[ $target == *"https://api.system.aws-jp01-pr.ice.predix.io"* ]];
then
  #echo "It's JAPAN!";
  uaaSuffixUrl="predix-uaa.run.aws-jp01-pr.ice.predix.io"
  assetUrl="https://predix-asset.run.aws-jp01-pr.ice.predix.io"
else
  error "Unknown environment"
fi


# Create a UAA instance
echo "Creating UAA instance \"uaa-test-eso\""
cf cs predix-uaa Free uaa-test-eso -c '{"adminClientSecret":"P@SSW0RD"}'

uaaGuid=$(cf service uaa-test-eso --guid)
printf "\e[30;48;5;82m OK ----> Created UAA GUID:$uaaGuid \e[0m \n"

#Create an Asset instance
echo "Creating Asset instance \"test-asset-eso\""
cf cs predix-asset Free test-asset-eso -c '{"trustedIssuerIds":["https://'$uaaGuid'.'$uaaSuffixUrl'/oauth/token"]}'
assetGuid=$(cf service test-asset-eso --guid)
printf "\e[30;48;5;82m OK ----> Created Asset GUID:$assetGuid \e[0m \n"
# Create a client using uaac
echo "Targeting UAA: https://${uaaGuid}.${uaaSuffixUrl}"
uaac target https://${uaaGuid}.${uaaSuffixUrl}
echo "Getting token for admin"
uaac token client get admin -s P@SSW0RD
echo "Adding client \"test-client\""
uaac client add test-client -s test-psw --authorized_grant_types "client_credentials password refresh_token" --autoapprove openid --authorities "clients.read clients.write scim.read scim.write predix-asset.zones.${assetGuid}.user"
echo "Getting token from client"
testToken=$(curl "https://${uaaGuid}.${uaaSuffixUrl}/oauth/token" -H 'Pragma: no-cache' -H 'content-type: application/x-www-form-urlencoded' -H 'Cache-Control: no-cache' -H 'authorization: Basic dGVzdC1jbGllbnQ6dGVzdC1wc3c=' --data 'client_id=test-client&grant_type=client_credentials' 2>/dev/null | jq -r .access_token)
echo "Adding data to Asset"
insertResponse=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $testToken" -H "Content-Type: application/json" -H "Predix-Zone-Id: $assetGuid" -H "Cache-Control: no-cache" -d '[ { "uri":"/eso-test-engine/ENG1.23", "serialNo":12345,"jetEnginePart":{ "uri":"/part/pt9876","sNo":55555 } }]' "$assetUrl/eso-test-engine")
if [ $insertResponse -eq 204 ]
then
  printf "\e[30;48;5;82m OK ----> Data inserted to Asset \e[0m \n"
else
  printf "\e[7;49;31;82m FAIL ----> Data NOT inserted to Asset \e[0m \n"
fi
assetData=$(curl -X GET -H "Authorization: Bearer $testToken" -H "Content-Type: application/json" -H "Predix-Zone-Id: $assetGuid" -H "Cache-Control: no-cache"  "$assetUrl/eso-test-engine")
printf "Getting inserted data: \n \033[33;32m$assetData \e[m \n"
echo "Deleting Asset instance"
cf ds test-asset-eso -f
echo "Deleting UAA instance"
cf ds uaa-test-eso -f
echo "Finish!!"
exit 0
