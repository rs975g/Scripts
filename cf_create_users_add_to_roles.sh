#!/bin/sh

#rm ~/Desktop/UserList.txt
predix_users=()
predix_org=' '
predix_spaces=( )

for i in "${predix_users[@]}"
 do
    echo $i
    echo "----------------"
   done


#for i in "${predix_users[@]}"
#do
#   password=`openssl rand -base64 16`
#   echo Hello $i.  Your account on the Predix Select environment has been created.  Your exact username::password is: $i::$password  >> ~/Desktop/UserList.txt
#   echo Please logon and change the password via 'cf passwd'  >> ~/Desktop/UserList.txt
#   echo '' >> ~/Desktop/UserList.txt
#   echo '' >> ~/Desktop/UserList.txt
#  cf create-user $i $password
#  echo $i set!
#done

  for space in "${predix_spaces[@]}"
    do
        for i in "${predix_users[@]}"
         do
                cf set-space-role $i $predix_org $space SpaceAuditor
                #cf set-space-role $i $predix_org $space SpaceManager
                #cf set-space-role $i $org $space SpaceDeveloper
        done
  done


for org in "${predix_org[@]}"
do
       for i in "${predix_users[@]}"
        do
                cf set-org-role $i $predix_org OrgAuditor
        done
done
