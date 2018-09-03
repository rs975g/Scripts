#!/bin/sh
#removes the user from org
#get the user guid from uaac


user_guids=()
org_name=()

for name in "${org_name[@]}";
do
orgs_guids=$(cf org "$name" --guid)
for i in "${user_guids[@]}";
do
   for org in "${orgs_guids[@]}"
   do
   cf curl /v2/organizations/$org/users/$i -X 'DELETE'
   echo "Removed $i from $name"
   echo "----------------------------------------------"
 done
done
done
