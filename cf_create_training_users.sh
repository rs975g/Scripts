#!/bin/sh

cf login -a https://api.grc-apps.svc.ice.ge.com -o test -s test --skip-ssl-validation

### predix-platform adoption users separated by a space for multiple users
### Add users inside the ( ) below:
predix_users=( )

predix_org=predix-adoption

predix_spaces=(training1 training2 training3)

for i in "${predix_users[@]}"; do echo $i; done;

#
#  Create the users with password = P@ssword1  <- Specifically requested by the Training team
#

for i in "${predix_users[@]}"; do cf create-user $i P@ssword1; done

#
#  Set the users as SpaceDevelopers 
#

for space in "${predix_spaces[@]}"
do 
	for i in "${predix_users[@]}"
	do 
		cf set-space-role $i $predix_org $space SpaceDeveloper
	done
done





