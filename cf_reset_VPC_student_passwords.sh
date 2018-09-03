#!/bin/bash

echo Reseting student user passwords in VPC

#VPC:
uaac target https://uaa.system.aws-usw02-pr.ice.predix.io
#R2:
#uaac target https://uaa.grc-apps.svc.ice.ge.com 

uaac token client get

rm ~/Desktop/trainingList.txt

i=1
count=76  #there are 75 training users

while [ $i -lt $count ]
do
   password=`openssl rand -base64 16`
   echo training$i  ::  $password >> ~/Desktop/trainingList.txt
   uaac password set training$i -p $password
   echo training$i set!

   let i=i+1
done
