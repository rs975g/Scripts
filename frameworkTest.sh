#!/bin/bash

#This script tests Analytics framework
#creates an uaa client, creates framework and adds the scopes to it.uaac cli needed
#flow downloads test app from git.
#Delete the instances

function halt() {
  #Since results might take time putting script to sleep whenever needed
  printf "\e[0;34;47m Waiting for analytic to complete the above step... \e[0m \n"
  time sleep $1
}

function error {
  printf "\e[7;49;31;82m $1 \e[0m \n"
  exit 1
}
target=$(cf t)

# Setting uaa and analytics urls based on cf t
if [[ $target == *"FAILED"* ]];
then
  error "FAIL ----> Not logged in to CF, please do \"cf login\""
elif [[ $target == *"https://api.system.aws-usw02-pr.ice.predix.io"* ]];
then
  #echo "It's BASIC!";
  uaaSuffixUrl="predix-uaa.run.aws-usw02-pr.ice.predix.io"
  catalogUrl="https://predix-analytics-catalog-release.run.aws-usw02-pr.ice.predix.io"
  executionUrl="https://predix-analytics-execution-release.run.aws-usw02-pr.ice.predix.io"
else
  error "Unknown environment"
fi


# Create a UAA instance
echo "Creating UAA instance \"uaa-test-support\""
cf cs predix-uaa Free uaa-test-support -c '{"adminClientSecret":"P@SSW0RD"}'

uaaGuid=$(cf service uaa-test-support --guid)
printf "\e[30;48;5;82m OK ----> Created UAA GUID:$uaaGuid \e[0m \n"

#Create a framework instance
echo "Creating framework instance \"test-framework-support\""
cf create-service predix-analytics-framework Free test-framework-support -c '{"trustedIssuerIds":["https://'$uaaGuid'.'$uaaSuffixUrl'/oauth/token"]}'
frameworkGuid=$(cf service test-framework-support --guid)
printf "\e[30;48;5;82m OK ----> Created framework GUID:$frameworkGuid \e[0m \n"

# Create a client using uaac
echo "Targeting UAA: https://${uaaGuid}.${uaaSuffixUrl}"
uaac target https://${uaaGuid}.${uaaSuffixUrl}
echo "Getting token for admin"
uaac token client get admin -s P@SSW0RD
echo "Adding client \"test-client\""
uaac client add test-client -s test-psw --authorized_grant_types "authorization_code client_credentials password refresh_token" --autoapprove "openid" --scope "analytics.zones.${frameworkGuid}.user" --authorities "clients.read clients.write scim.read scim.write analytics.zones.${frameworkGuid}.user"
echo "Getting token from client"
testToken=$(curl "https://${uaaGuid}.${uaaSuffixUrl}/oauth/token" -H 'Pragma: no-cache' -H 'content-type: application/x-www-form-urlencoded' -H 'Cache-Control: no-cache' -H 'authorization: Basic dGVzdC1jbGllbnQ6dGVzdC1wc3c=' --data 'client_id=test-client&grant_type=client_credentials' 2>/dev/null | jq -r .access_token)

#git clone the sample analytic
echo "Downloading sample analytic.."
curl -LO https://github.com/PredixDev/predix-analytics-sample/releases/download/2016-Q3-release/demo-adder-java-1.0.0.jar
temp=@$(pwd)/demo-adder-java-1.0.0.jar
printf "\e[30;48;5;82m Downloaded to $temp \e[0m \n"

#Create an analytic catalog Entry
echo "creating catalog Entry.."
catalogEntryResponse=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $testToken" -H 'Content-Type: application/json' -H "Predix-Zone-Id: $frameworkGuid" -H 'Cache-Control: no-cache' -d '{
    "name": "testsupport",
    "version": "v1",
    "supportedLanguage": "Java",
    "taxonomyLocation": "",
    "author": "test",
    "description": "test",
    "customMetadata": "{\"assetid\":\"abc\"}"
}' "$catalogUrl/api/v1/catalog/analytics" | jq .)
echo $catalogEntryResponse | jq .
#analyticId=$(echo "$catalogEntryResponse" | head -2| tail -1)
#analyticId=$(echo "$catalogEntryResponse" | grep \"id\")
analyticId=$(echo "$catalogEntryResponse" | head -14| jq .id|awk -F '"' '{print $2}')
respcode=$(echo "$catalogEntryResponse" | tail -1)
if [ $respcode -eq 201 ]
then
  printf "\e[30;48;5;82m OK ----> analytic id GUID:$analyticId Created \e[0m \n"
else
  error "FAIL ----> failed to create analytic"
fi

#analytic logs
function analyticLogs() {
  echo "getting the logs..."
  curl -s -w "%{http_code}" -X GET -H "Authorization: Bearer $testToken" -H 'content-type: application/json' -H "Predix-Zone-Id: $frameworkGuid" -H "Cache-Control: no-cache"  "$catalogUrl/api/v1/catalog/analytics/$analyticId/logs"
}

#upload the analytic
echo "uploading the analytic.."
catalogUploadResponse=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $testToken" -H 'Content-Type: multipart/form-data' -H 'accept: application/json' -H "Predix-Zone-Id: $frameworkGuid" -H "Cache-Control: no-cache" -F "file=$temp" -F "catalogEntryId=$analyticId" -F 'type=Executable' -F 'description=demoadder' "$catalogUrl/api/v1/catalog/artifacts" | jq .)
echo "$catalogUploadResponse" | jq .
respcode1=$(echo "$catalogUploadResponse" | tail -1)
if [ $respcode1 -eq 201 ]
then
  printf "\e[30;48;5;82m OK ----> analytic upload to $analyticId  \e[0m \n"
else
  analyticLogs
  error "FAIL ----> failed to upload analytic"
fi

#validate the analytic
echo "validating the analytic.."
validateAnalyticResponse=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $testToken" -H "Content-Type: application/json" -H "Predix-Zone-Id: $frameworkGuid" -H "Cache-Control: no-cache"  -d '{"number1":1,"number2":2}' "$catalogUrl/api/v1/catalog/analytics/$analyticId/validation" | jq .)
echo "$validateAnalyticResponse" | jq .
validateId=$(echo "$validateAnalyticResponse" | head -10| jq .validationRequestId|awk -F '"' '{print $2}')
respcode2=$(echo "$validateAnalyticResponse" | tail -1)
if [ $respcode2 -eq 200 ]
then
  printf "\e[30;48;5;82m OK ----> analytic id GUID:$analyticId validated $validateId \e[0m \n"
else
  analyticLogs
  error "failed to validate analytic"
fi

#halt for 5sec
halt 5

#Get the analytic result
function analyticResultFun() {
  echo "Getting the analytic result.."
  analyticResult=$(curl -s -w "%{http_code}" -X GET -H "Authorization: Bearer $testToken" -H 'content-type: application/json' -H "Predix-Zone-Id: $frameworkGuid" -H "Cache-Control: no-cache"  "$catalogUrl/api/v1/catalog/analytics/$analyticId/validation/$validateId" | jq .)
  echo "$analyticResult" | jq .
  respcode3=$(echo "$analyticResult" | tail -1)
  statusId=$(echo "$analyticResult" | head -10| jq .status |awk -F '"' '{print $2}')
  if [ $respcode3 -eq 200 ]
  then
    while [[ "$statusId" = "PROCESSING" ]]
    do
      halt 30
      analyticResultFun
    done
    while [[ "$statusId" = "QUEUED" ]]
    do
      halt 15
      analyticResultFun
    done
    while [[ "$statusId" = "FAILED" ]]
    do
      analyticLogs
      error "Analytic failed. please review logs"
    done
    printf "\e[30;48;5;82m OK ----> analytic result GUID:$analyticId validated $validateId \e[0m \n"
  else
    analyticLogs
    error "failed to get analytic result"
  fi
}

analyticResultFun

#Deploy the analytic
echo "Deploying the Analytic ..."
deployAnalytic=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $testToken" -H "Content-Type: application/json" -H "Predix-Zone-Id: $frameworkGuid" -H "Cache-Control: no-cache" -d '{"memory":512,"diskQuota":1024,"instances":1}' "$catalogUrl/api/v1/catalog/analytics/$catalogEntryId/deployment" | jq .)
echo "$deployAnalytic" | jq .
deployId=$(echo "$deployAnalytic" | head -10| jq .requestId|awk -F '"' '{print $2}')
respcode4=$(echo "$deployAnalytic" | tail -1)
if [ $respcode4 -eq 200 ]
then
  printf "\e[30;48;5;82m OK ----> analytic deployed GUID:$analyticId with $deployId \e[0m \n"
else
  analyticLogs
  error "FAIL ----> failed to deploy analytic"
fi

#check the deployement status
function deploymentStatus() {
  echo "checking the deployement status"
  deployStatus=$(curl -s -w "%{http_code}" -X GET -H "Authorization: Bearer $testToken" -H 'content-type: application/json' -H "Predix-Zone-Id: $frameworkGuid" -H "Cache-Control: no-cache"  "$catalogUrl/api/v1/catalog/analytics/$analyticId/deployment/$deployId" | jq .)
  echo "$deployStatus" | jq .
  statusId2=$(echo "$deployStatus" | head -10| jq .status |awk -F '"' '{print $2}')
  respcode5=$(echo "$deployStatus" | tail -1)
  if [ $respcode5 -eq 200 ]
  then
    while [[ "$statusId2" = "PROCESSING" ]]
    do
      halt 30
      deploymentStatus
    done
    while [[ "$statusId2" = "QUEUED" ]]
    do
      halt 15
      deploymentStatus
    done
    while [[ "$statusId" = "FAILED" ]]
    do
      analyticLogs
      error "Analytic deployement failed. please review logs"
    done
    printf "\e[30;48;5;82m OK ----> analytic deployed GUID:$analyticId with $deployId \e[0m \n"
  else
    analyticLogs
    error "FAIL ----> failed to deploy analytic"
  fi
}

deploymentStatus

#Run analytic
echo "Running the analytic"
runAnalytic=$(curl -s -w "%{http_code}" -X POST -H "Authorization: Bearer $testToken" -H "Content-Type: application/json" -H "Predix-Zone-Id: $frameworkGuid" -H "Cache-Control: no-cache"  -d '{"number1":1,"number2":2}' "$catalogUrl/api/v1/catalog/analytics/$analyticId/execution" | jq .)
echo "$runAnalytic" | jq .
respcode5=$(echo "$runAnalytic" | tail -1)
if [ $respcode5 -eq 200 ]
then
  printf "\e[30;48;5;82m OK ----> analytic executed GUID:$analyticId \e[0m \n"
else
  analyticLogs
  error "FAIL ----> failed to run analytic"
fi

#Execute analytic
echo "Executing the analytic"
executeAnalytic=$(curl -s -w "%{http_code}" -X POST -H "Predix-Zone-Id: $frameworkGuid" -H "Authorization: Bearer $testToken" -H 'content-type: application/json' -d '{	"id": "sid-33430087-7a44-4be3-8517-914faf923288",
	"name": "Demo SimpleMath Orchestration",
	"bpmnXml": "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <definitions xmlns=\"http://www.omg.org/spec/BPMN/20100524/MODEL\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" expressionLanguage=\"http://www.w3.org/1999/XPath\" id=\"sid-81430087-7a44-4be3-8517-914faf923256\" targetNamespace=\"DSP-PM\" typeLanguage=\"http://www.w3.org/2001/XMLSchema\" xsi:schemaLocation=\"http://www.omg.org/spec/BPMN/20100524/MODEL http://www.omg.org/spec/BPMN/2.0/20100501/BPMN20.xsd\" xmlns:activiti=\"http://activiti.org/bpmn\"> <process id=\"DemoAdderWorklow\" isExecutable=\"true\"> <startEvent id=\"sid-start\" name=\"\"> <outgoing>sid-flow1</outgoing> </startEvent> <serviceTask completionQuantity=\"1\" id=\"sid-10001\" isForCompensation=\"false\" name=\"$analyticId::testsupport::v1\" startQuantity=\"1\" activiti:delegateExpression=\"${javaDelegate}\" xmlns:activiti=\"http://activiti.org/bpmn\"> <incoming>sid-flow1</incoming> <outgoing>sid-flow2</outgoing> </serviceTask> <serviceTask completionQuantity=\"1\" id=\"sid-10002\" isForCompensation=\"false\" name=\"$analyticId::testsupport::v1\" startQuantity=\"1\" activiti:delegateExpression=\"${javaDelegate}\" xmlns:activiti=\"http://activiti.org/bpmn\"> <incoming>sid-flow2</incoming> <outgoing>sid-flow3</outgoing> </serviceTask> <endEvent id=\"sid-end\" name=\"\"> <incoming>sid-flow3</incoming> </endEvent> <sequenceFlow id=\"sid-flow1\" name=\"\" sourceRef=\"sid-start\" targetRef=\"sid-10001\"/> <sequenceFlow id=\"sid-flow2\" name=\"\" sourceRef=\"sid-10001\" targetRef=\"sid-10002\"/> <sequenceFlow id=\"sid-flow3\" name=\"\" sourceRef=\"sid-10002\" targetRef=\"sid-end\"/> </process> </definitions>",
	"analyticInputData":
	[
	{
		"analyticStepId": "sid-10001",
		"data": "{ \"number1\": 21, \"number2\": 4 }"
	},
	{
		"analyticStepId": "sid-10002",
		"data": "{ \"number1\": 25, \"number2\": 4 }"
	}
	]}' "$catalogUrl/api/v1/execution")
echo "$executeAnalytic" | jq .

#cleaning up
cf ds test-framework-support -f
cf ds uaa-test-support -f
printf "\e[30;48;5;82m Deleted all the instances in CF. Please Delete the demo analytic from your local \e[0m \n"
echo "-------------"
