if [ $# -eq 0 ] || [ ! "$1" = "-f" ] || [ ! "$3" = "-v" ] || [ ! "$5" = "-u" ] || [ ! "$7" = "-t" ] || [ ! "$9" = "-a" ]
  then
    echo "Incorrect format. Format must be: ./rollback_tenant.sh -f <file-name> -v <sysint, asv or asv-staging> -u <y/n delete uaa> -t <y/n delete time series> -a <y/n delete asset>"
    exit 1
fi

INPUT_FILE=$2
ENV=$4
DELETE_UAA=$6
DELETE_TS=$8
DELETE_ASS="$10"

if [ ! -f "$INPUT_FILE" ]
  then
    "File $INPUT_FILE not found."
    exit 1
fi
source $INPUT_FILE
echo "Using input file $INPUT_FILE"

if [ "$ENV" = "sysint" ]; then

    echo
    echo "*******************************************************"
    echo "**********************SYSINT***************************"
    echo "*******************************************************"
    echo

    TMS_STATIC_ROUTE_HOST=tms-sysint
    CF_BASE_DOMAIN=grc-apps.svc.ice.ge.com
    UAA_HOST_NAME=predix-uaa-sysint
    EDGEMANAGER_TENANT_URL=https://edgemanager-sysint.grc-apps.svc.ice.ge.com/svc/tenant/v1/tenant
    EDGEMANAGER_DEFAULT_UAA=https://77f263ce-67e4-4834-b4e6-3353c374e252.predix-uaa-staging.grc-apps.svc.ice.ge.com
    EDGEMANAGER_TENANT_CLIENT_ID=em-tenant-manager
    EDGEMANAGER_TENANT_CLIENT_SECRET=em-tenant-manager-secret
    APP_ID=predix-edge
elif [ "$ENV" = "asv" ]; then

    echo
    echo "*******************************************************"
    echo "**********************ASV***************************"
    echo "*******************************************************"
    echo

    TMS_STATIC_ROUTE_HOST=tms-asv-pr
    CF_BASE_DOMAIN=run.asv-pr.ice.predix.io
    UAA_HOST_NAME=predix-uaa
    EDGEMANAGER_DEFAULT_UAA=https://242c46e4-4c7a-4c98-b9b1-8857979bc1b0.predix-uaa.run.asv-pr.ice.predix.io
    EDGEMANAGER_TENANT_CLIENT_ID=em-tenant-manager
    EDGEMANAGER_TENANT_CLIENT_SECRET=o4DU_Bevk-BBDfrf
    EDGEMANAGER_TENANT_URL=https://edgemanager.run.asv-pr.ice.predix.io/svc/tenant/v1/tenant
    APP_ID=predix-edge
elif [ "$ENV" = "asv-staging" ]; then

    echo
    echo "*******************************************************"
    echo "**********************ASV***************************"
    echo "*******************************************************"
    echo

    TMS_STATIC_ROUTE_HOST=tms-asv-pr
    CF_BASE_DOMAIN=run.asv-pr.ice.predix.io
    UAA_HOST_NAME=predix-uaa
    EDGEMANAGER_DEFAULT_UAA=https://uaa-test.run.asv-pr.ice.predix.io
    EDGEMANAGER_TENANT_CLIENT_ID=em-tenant-manager
    EDGEMANAGER_TENANT_CLIENT_SECRET=qWPeGV9J2SGaE_l
    EDGEMANAGER_TENANT_URL=https://edgemanager-asvf5.run.asv-pr.ice.predix.io/svc/tenant/v1/tenant
    APP_ID=predix-edge-staging
else
  echo "Please enter sysint or asv!"
  exit 1
fi

TMS_INSTANCE_NAME=predix-edge-tms-$TENANT_NAME
TMS_INSTANCE_ID=$(cf service $TMS_INSTANCE_NAME --guid)
TMS_SERVICE_URL=https://$TMS_STATIC_ROUTE_HOST.$CF_BASE_DOMAIN
TMS_CLIENT=$TENANT_NAME-tms-client
TMS_CLIENT_SECRET=pm5ecret
ZAC_UAA_URL=https://$UAA_HOST_NAME.$CF_BASE_DOMAIN
ZAC_CLIENT=zac-em-client
ZAC_CLIENT_SECRET=zac-em-client-secret
GRP_ROLE_PREFIX=edgemanager


echo "Rolling back tenant $TENANT_NAME"
echo "Tenant uaa url $TENANT_UAA_URL"

#Delete tenant from TMS
uaac target $TENANT_UAA_URL --skip-ssl-validation
uaac token client get $TMS_CLIENT -s $TMS_CLIENT_SECRET

# This needs to be delete first
uaac curl -XDELETE \
    -H "Content-Type: application/json" \
    -H "Predix-Zone-Id:$TMS_INSTANCE_ID" \
    $TMS_SERVICE_URL/v1/tenant/$TENANT_NAME


 #Delete Timeseries and UAA instances if specified
if [ "$DELETE_UAA" = "y" ]
  then
    cf ds tms-predix-uaa-$TENANT_NAME -f
  else
    uaac target $TENANT_UAA_URL --skip-ssl-validation
    uaac token client get $TENANT_UAA_ADMIN -s $TENANT_UAA_ADMIN_SECRET

    #Delete admin user
    uaac user delete $TENANT_NAME-admin
    #Delete tms client
    uaac client delete $TENANT_NAME-tms-client #admin
    #Delete groups
    uaac group delete $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Administrator #admin
    uaac group delete $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Operator
    uaac group delete $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Technician
    uaac group delete $GRP_ROLE_PREFIX.zones.$TENANT_NAME.TempRole
    uaac group delete $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Enrollment
    uaac group delete $APP_ID.zones.$TENANT_NAME.user
    #Delete app client
    uaac client delete $TENANT_NAME-app-client #admin
fi
if [ "$DELETE_TS" = "y" ]
  then
    cf ds timeseries-$TENANT_NAME -f
fi
if [ "$DELETE_ASS" = "y" ]
  then
    cf ds asset-$TENANT_NAME -f
fi

#Delete TMS instance
cf ds predix-edge-tms-$TENANT_NAME -f


#Delete tenant from tenant mgmt service
uaac target $EDGEMANAGER_DEFAULT_UAA
uaac token client get $EDGEMANAGER_TENANT_CLIENT_ID -s $EDGEMANAGER_TENANT_CLIENT_SECRET

uaac curl -XDELETE \
	$EDGEMANAGER_TENANT_URL/$TENANT_NAME