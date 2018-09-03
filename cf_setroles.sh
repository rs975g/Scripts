#!/bin/sh
#if you have a list of user whose roles need to be set, use this. 
predix_users=()
predix_spaces=()
for i in "${predix_users[@]}"; do echo $i; done;
echo "------------------------------------"
for space in "${predix_spaces[@]}"
do
   for i in "${predix_users[@]}"
    do

       #cf curl -X PUT /v2/spaces/$space/developers -d '{"username":"$i"}'
       cf curl -X PUT /v2/spaces/$space/developers/$i
       echo "$i added to $space "
     done
   done
