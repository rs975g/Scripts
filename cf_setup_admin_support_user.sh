#!/bin/sh

uaac target https://uaa.grc-apps.svc.ice.ge.com
uaac token client get sst_support -s yYEl4GM5WYPq9g==

### predix-platform adoption users
uaa_scopes=(approvals.me clients.read clients.write cloud_controller_service_permissions.read cloud_controller.admin cloud_controller.read cloud_controller.write notification_preferences.read notification_preferences.write oauth.approvals openid password.write scim.me scim.read scim.write uaa.admin uaa.user)

echo $1

for i in "${uaa_scopes[@]}"; do echo $i; done;

#
#  use uaac to add the user to the list of roles.
#

for i in "${uaa_scopes[@]}"; do uaac member add $i $1; done

