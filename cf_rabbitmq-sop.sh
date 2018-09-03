
#!/bin/sh

### Login to colo environment Predix support and test-sops space
cf login -a https://api.system.asv-pr.ice.predix.io -o predix-support -s test-sop --skip-ssl-validation

sleep 3

cf unbind-service predix-support-spring-cloud-app rabbitmq-sop-test

cf unbind-service predix-support-spring-cloud-app postgres-sop-test

cf ds rabbitmq-sop-test -f

cf ds postgres-sop-test -f
### Create service instance of Rabbit-Mq
cf cs p-rabbitmq-35 standard rabbitmq-sop-test

### Create service instance of Postgres
cf cs postgres shared-nr postgres-sop-test
###Bind Service instance to predix-support-spring-cloud-app
cf bs predix-support-spring-cloud-app rabbitmq-sop-test

###Bind Service instance to predix-support-spring-cloud-app

cf bs predix-support-spring-cloud-app postgres-sop-test

####Restage predix-support-spring-cloud-app
cf restage predix-support-spring-cloud-app

if ($?=0)
then
echo "The app is installed sucessfully"
else
echo "Please check the logs for failure"

fi

echo "Sleeps for  120 secs to test the application "
sleep 120

####Stopping the app predix-support-spring-cloud-app

cf stop predix-support-spring-cloud-app
##Unbinding Rabbit service instance
cf unbind-service predix-support-spring-cloud-app rabbitmq-sop-test

####Unbinding Postgres service instance
cf unbind-service predix-support-spring-cloud-app postgres-sop-test

####Deleting RabbitMq service instance

cf ds rabbitmq-sop-test -f

####Deleting postgres service instance
cf ds postgres-sop-test -f
