#!/bin/sh

cf login -a https://api.grc-apps.svc.ice.ge.com --skip-ssl-validation

### predix-platform adoption users
predix_users=( )

predix_org=predix-adoption

predix_spaces=(training1)

for i in "${predix_users[@]}"; do echo $i; done;

#
#  Unset the users as SpaceDevelopers 
#

for space in "${predix_spaces[@]}"
do 
	for i in "${predix_users[@]}"
	do 
		cf unset-space-role $i $predix_org $space SpaceDeveloper
	done
done





