#!/bin/bash

#this scripts changes the old rmq to new rmq and restages the exisiting analytics.

tenant=`cf t | awk 'NR > 4 { print }' | cut -f 11 -d " "`
cf cs analytics-rabbitmq-36 standard rabbitmq-$tenant-new
cf rename-service rabbitmq-$tenant old-rabbitmq-$tenant
cf rename-service rabbitmq-$tenant-new rabbitmq-$tenant
for app in `cf a|awk 'NR > 4 { print }'|cut -f 1 -d " "`
do
	cf us $app old-rabbitmq-$tenant
	cf bs $app rabbitmq-$tenant
	cf restage $app
done
cf ds -f old-rabbitmq-$tenant
