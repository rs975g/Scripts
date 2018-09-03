#!/bin/bash

uaac target https://uaa.grc-apps.svc.ice.ge.com
uaac token client get sst_support -s yYEl4GM5WYPq9g==

### predix-platform adoption users
uaa_scopes=(scim.read)
#users=(john.kruger@ge.com)
users=($1)

#
#  use uaac to add the user to the list of roles.
#

for i in "${users[@]}"
do 
	for j in "${uaa_scopes[@]}"
	do
		echo -n Adding $j to user $i -- 
		uaac member add $j $i
	done
done
