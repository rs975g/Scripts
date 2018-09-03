#Exit if a command fails
err_report() {
    echo
    echo "Error occurred on line $1 of the script. Writing available output values to file $TENANT_NAME.out..."
    echo "Exiting now"

    write_to_output
    exit 1
}
trap 'err_report ${LINENO}' ERR

write_to_output()
{
  echo TENANT_NAME=$TENANT_NAME >> $TENANT_NAME.out
  echo TENANT_UAA_URL=$TENANT_UAA_URL >> $TENANT_NAME.out
  echo TMS_INSTANCE_ID=$TMS_INSTANCE_ID >> $TENANT_NAME.out

  echo TIMESERIES_INSTANCE_NAME=$TIMESERIES_INSTANCE_NAME >> $TENANT_NAME.out
  if [ ! -z $TIME_SERIES_GUID ]; then
     echo TIMESERIES_INSTANCE_ID=$TIME_SERIES_GUID >> $TENANT_NAME.out
  fi

  echo ASSET_INSTANCE_NAME=$ASSET_INSTANCE_NAME >> $TENANT_NAME.out
  if [ ! -z $ASSET_GUID ]; then
     echo ASSET_INSTANCE_ID=$ASSET_GUID >> $TENANT_NAME.out
  fi

  echo TENANAT_ADMIN_USER=$TENANT_NAME-admin >> $TENANT_NAME.out
  echo TENANT_ADMIN_PASS=chang3m3 >> $TENANT_NAME.out
  echo APPLICATION_CLIENT=$APP_CLIENT_ID >> $TENANT_NAME.out
  echo APPLICATION_CLIENT_SECRET=$APP_CLIENT_SECRET >> $TENANT_NAME.out
  echo TENANT_UAA_ADMIN=$TENANT_UAA_ADMIN >> $TENANT_NAME.out
  echo TENANT_UAA_ADMIN_SECRET=$TENANT_UAA_ADMIN_SECRET >> $TENANT_NAME.out
  echo EDGEMANAGER_URL=https://$TENANT_NAME.$EDGEMANAGER_BASE_DOMAIN >> $TENANT_NAME.out
  echo "$TENANT_NAME provision completed."
}

incorrect_args()
{
  echo "Incorrect format. Format must be:
        ./create_tenant_instance -n <tenant name> -p <prosyst key type> -o <OrgName> -v <sysint, asv or asv-staging> -u <enter y to create new uaa, n to use existing>
        [-i <uaa instance to use> -c <uaa admin client id> -s <uaac admin secret>] -t <Enter y/n to create time series, or x to use existing> [-x <time series instance to use> ]
        -y <Enter y/n to create asset, or z to use existing> [-z <asset instance to use> ] "
  exit 1
}

function get_args(){
  while getopts "n:p:o:v:u:i:c:s:t:x:y:z:" opt; do
    case $opt in
      n)
      TENANT_NAME=$OPTARG
      ;;
      p)
      PROSYST_KEY_TYPE=$OPTARG
      ;;
      o)
      ORG_NAME=$OPTARG
      ;;
      v)
      ENVIRONMENT=$OPTARG
      ;;
      u)
      CREATE_UAA=$OPTARG
      ;;
      i)
      TENANT_UAA_URL=$OPTARG
      ;;
      c)
      TENANT_UAA_ADMIN=$OPTARG
      ;;
      s)
      TENANT_UAA_ADMIN_SECRET=$OPTARG
      ;;
      t)
      CREATE_TIMESERIES=$OPTARG
      ;;
      x)
      TIMESERIES_INSTANCE_NAME=$OPTARG
      ;;
      y)
      CREATE_ASSET=$OPTARG
      ;;
      z)
      ASSET_INSTANCE_NAME=$OPTARG
      ;;
      \?)
      echo "Invalid option -$OPTARG"
      incorrect_args
      ;;
    esac
  done
}

function validate_inputs(){
  if [ -z "$TENANT_NAME" ]; then
     echo "tenant name -n is required."
     incorrect_args
    exit 1
  fi

  if [ -z "$PROSYST_KEY_TYPE" ]; then
     echo "prosyst key type -p is required."
     incorrect_args
     exit 1
  fi

  if [ -z "$ORG_NAME" ]; then
     echo "org name -o is required."
     incorrect_args
    exit 1
  fi

  if [ -z "$ENVIRONMENT" ]; then
     echo "ENVIRONMENT -v is required."
     incorrect_args
    exit 1
  fi

  if [ -z "$CREATE_UAA" ]; then
     echo "CREATE_UAA -u is required."
     incorrect_args
    exit 1
  fi

  if ! [[ "$CREATE_UAA" =~ ^[yn]$ ]]; then
     echo "CREATE_UAA -u must be followed by either y or n."
     incorrect_args
    exit 1
  fi

  if [ "$CREATE_UAA" = "n" ]; then
    if [ -z "$TENANT_UAA_URL" ] || [ -z "$TENANT_UAA_ADMIN" ] || [ -z "$TENANT_UAA_ADMIN_SECRET" ]
    then
    echo "UAA instance url -i, admin client id -c and secret -s must be provided when entering 'n' for using an existing uaa instance"
    incorrect_args
    exit 1
    fi
  fi

  if [ -z "$CREATE_TIMESERIES" ]; then
     echo "CREATE_TIMESERIES -t is required."
     incorrect_args
    exit 1
  fi

  if ! [[ "$CREATE_TIMESERIES" =~ ^[yn]$ ]]; then
     echo "CREATE_TIMESERIES -t must be followed by either y or n."
     incorrect_args
    exit 1
  fi

  if [ "$CREATE_TIMESERIES" = "n" ]; then
    if [ -z "$TIMESERIES_INSTANCE_NAME" ]
    then
    echo "Time series instance name -x must be provided for using an exisiting time series"
    incorrect_args
    exit 1
    fi
  fi

  if [ "$CREATE_TIMESERIES" = "y" ]; then
    if [ ! -z "$TIMESERIES_INSTANCE_NAME" ]
    then
    echo "************ WARNING: Time series instance name is provide but CREATE_TIMESERIES value is set to YES. The script is going to create a new timeseries instance! ***************"
    fi
  fi

  if [ -z "$CREATE_ASSET" ]; then
     echo "CREATE_ASSET -y is required."
     incorrect_args
    exit 1
  fi

  if ! [[ "$CREATE_ASSET" =~ ^[yn]$ ]]; then
     echo "CREATE_ASSET -z must be followed by either y or n."
     incorrect_args
    exit 1
  fi

  if [ "$CREATE_ASSET" = "n" ]; then
    if [ -z "$ASSET_INSTANCE_NAME" ]
    then
    echo "Asset instance name -z must be provided for using an exisiting asset"
    incorrect_args
    exit 1
    fi
  fi

  if [ "$CREATE_ASSET" = "y" ]; then
    if [ ! -z "$ASSET_INSTANCE_NAME" ]
    then
    echo "************WARNING: Asset instance name is provide but CREATE_ASSET value is set to YES. The script is going to create a new asset instance! ***************"
    fi
  fi

}

get_args $*
validate_inputs

echo      "TENANT_NAME: " $TENANT_NAME
echo      "PROSYST_KEY_TYPE: " $PROSYST_KEY_TYPE
echo      "ORG_NAME: " $ORG_NAME
echo      "ENVIRONMENT: " $ENVIRONMENT
echo      "CREATE_UAA: " $CREATE_UAA
echo      "TENANT_UAA_URL: " $TENANT_UAA_URL
echo      "TENANT_UAA_ADMIN: " $TENANT_UAA_ADMIN
echo      "TENANT_UAA_ADMIN_SECRET: " $TENANT_UAA_ADMIN_SECRET
echo      "CREATE_TIMESERIES: " $CREATE_TIMESERIES
echo      "TIMESERIES_SERVICE_NAME: " $TIMESERIES_INSTACNE_NAME
echo      "CREATE_ASSET: " $CREATE_ASSET
echo      "ASSET_SERVICE_NAME: " $ASSET_INSTANCE_NAME


if [ "$ENVIRONMENT" = "sysint" ]; then

    echo "*******************************************************"
    echo "**********************SYSINT***************************"
    echo "*******************************************************"
    echo
    UAA_HOST_NAME=predix-uaa-sysint
    UAA_NAME_STAGING=predix-uaa-staging #TMS Staging UAA -- This is needed only in sysint environment - for workaround. Ideally It should be same as UAA_HOST_NAME
    UAA_SERVICE_NAME=predix-uaa #Service name in the marketplace
    UAA_PLAN=free

    TIMESERIES_SERVICE_NAME=predix-timeseries-release
    TIMESERIES_PLAN=Beta

    ASSET_SERVICE_NAME=predix-asset-dev
    ASSET_PLAN=Tiered
    ASSET_URL=http://predix-asset-rc.grc-apps.svc.ice.ge.com


    TMS_HOST_NAME=tms-predix-sysint #TMS hostname used in wild card routing
    TMS_SERVICE_NAME=predix-tms-sysint #TMS service name found in the marketplace
    TMS_PLAN=Free
    TMS_SERVICE_ID=predix-tms-sysint
    TMS_STATIC_ROUTE_HOST=tms-sysint #TMS host name used in static routing

    CF_BASE_DOMAIN=grc-apps.svc.ice.ge.com  #The base domain

    EDGEMANGER_APP_NAME=edgemanager-sysint
    EDGEMANAGER_BASE_DOMAIN=edgemanager-sysint.grc-apps.svc.ice.ge.com
    ZAC_REGISTRATION_URL=https://zac-release.grc-apps.svc.ice.ge.com/v1/registration
    ZAC_WRITE_CLIENT_ID=zac-device-management-client
    ZAC_WRITE_CLIENT_SECRET=zacsecret-gu@rdian
    EDGEMANAGER_DEFAULT_UAA=https://77f263ce-67e4-4834-b4e6-3353c374e252.predix-uaa-staging.grc-apps.svc.ice.ge.com
    EDGEMANAGER_TENANT_CLIENT_ID=em-tenant-manager
    EDGEMANAGER_TENANT_CLIENT_SECRET=em-tenant-manager-secret
    EDGEMANAGER_TENANT_URL=https://edgemanager-sysint.grc-apps.svc.ice.ge.com/svc/tenant/v1/tenant
    APP_ID=predix-edge
    PROXIMETRY_APP_ID=proximetry
elif [ "$ENVIRONMENT" = "asv" ]; then

    echo "*******************************************************"
    echo "**********************ASV***************************"
    echo "*******************************************************"
    echo
    UAA_HOST_NAME=predix-uaa
    UAA_NAME_STAGING=predix-uaa
    UAA_SERVICE_NAME=predix-uaa
    UAA_PLAN=Tiered

    TIMESERIES_SERVICE_NAME=predix-timeseries
    TIMESERIES_PLAN=Bronze

    TMS_HOST_NAME=predix-tms #TMS hostname used in wild card routing
    TMS_SERVICE_NAME=predix-tms #TMS service name found in the marketplace
    TMS_PLAN=Tiered
    TMS_SERVICE_ID=predix-tms
    TMS_STATIC_ROUTE_HOST=tms-asv-pr

    ASSET_SERVICE_NAME=predix-asset
    ASSET_PLAN=Tiered
    ASSET_URL=https://predix-asset.run.asv-pr.ice.predix.io

    CF_BASE_DOMAIN=run.asv-pr.ice.predix.io

    EDGEMANGER_APP_NAME=edgemanager
    EDGEMANAGER_BASE_DOMAIN=edgemanager.$CF_BASE_DOMAIN
    ZAC_REGISTRATION_URL=https://predix-zac.run.asv-pr.ice.predix.io/v1/registration
    ZAC_WRITE_CLIENT_ID=zac-device-management-client
    ZAC_WRITE_CLIENT_SECRET=zacsecret-gu@rdian
    EDGEMANAGER_DEFAULT_UAA=https://242c46e4-4c7a-4c98-b9b1-8857979bc1b0.predix-uaa.run.asv-pr.ice.predix.io
    EDGEMANAGER_TENANT_CLIENT_ID=em-tenant-manager
    EDGEMANAGER_TENANT_CLIENT_SECRET=o4DU_Bevk-BBDfrf
    EDGEMANAGER_TENANT_URL=https://edgemanager.run.asv-pr.ice.predix.io/svc/tenant/v1/tenant
    APP_ID=predix-edge
    PROXIMETRY_APP_ID=proximetry
elif [ "$ENVIRONMENT" = "asv-staging" ]; then

    echo "*******************************************************"
    echo "**********************ASV staging***************************"
    echo "*******************************************************"
    echo
    UAA_HOST_NAME=predix-uaa
    UAA_NAME_STAGING=predix-uaa
    UAA_SERVICE_NAME=predix-uaa
    UAA_PLAN=Tiered

    TIMESERIES_SERVICE_NAME=predix-timeseries
    TIMESERIES_PLAN=Bronze

    TMS_HOST_NAME=predix-tms #TMS hostname used in wild card routing
    TMS_SERVICE_NAME=predix-tms #TMS service name found in the marketplace
    TMS_PLAN=Tiered
    TMS_SERVICE_ID=predix-tms
    TMS_STATIC_ROUTE_HOST=tms-asv-pr

    ASSET_SERVICE_NAME=predix-asset
    ASSET_PLAN=Tiered
    ASSET_URL=https://predix-asset.run.asv-pr.ice.predix.io

    CF_BASE_DOMAIN=run.asv-pr.ice.predix.io

    EDGEMANGER_APP_NAME=edgemanager
    EDGEMANAGER_BASE_DOMAIN=edgemanager-asvf5.$CF_BASE_DOMAIN
    ZAC_REGISTRATION_URL=https://predix-zac.run.asv-pr.ice.predix.io/v1/registration
    ZAC_WRITE_CLIENT_ID=zac-device-management-staging-client
    ZAC_WRITE_CLIENT_SECRET=EP5ZPA2N5rlLP1o4f7RaJrwuXotC9J0svw==
    EDGEMANAGER_DEFAULT_UAA=https://uaa-test.run.asv-pr.ice.predix.io
    EDGEMANAGER_TENANT_CLIENT_ID=em-tenant-manager
    EDGEMANAGER_TENANT_CLIENT_SECRET=qWPeGV9J2SGaE_l
    EDGEMANAGER_TENANT_URL=https://edgemanager-asvf5.run.asv-pr.ice.predix.io/svc/tenant/v1/tenant
    APP_ID=predix-edge-staging
    PROXIMETRY_APP_ID=proximetry-staging
else
  echo "Please enter sysint, asv, or asv-staging"
  exit 1
fi

if [ ! "$PROSYST_KEY_TYPE" == "limited" ] && [ ! "$PROSYST_KEY_TYPE" == "unlimited" ]; then
  echo "Please enter 'limited or 'unlimited' for the Prosyst key type"
  exit 1
fi

#Generate a random password of length 15 using /dev/urandom
generate_app_secret()
{
    KEYPASS=`head -c 500 /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9-_" | head -c 15`
}
generate_app_secret


TENANT_ADMIN=$TENANT_NAME-admin
TENANT_ADMIN_EMAIL=test-admin@ge.com
TENANT_ADMIN_PASS=chang3m3
TENANT_SUBDOMAIN=$TENANT_NAME

TIME_SERIES_SERVICE_INSTANCE_NAME=NA #This value is being set to tenant mgmt service but is not used

TENANT_UAA_NAME=tms-$UAA_SERVICE_NAME-$TENANT_NAME #Name of the UAA to be created

TMS_INSTANCE_NAME=predix-edge-tms-$TENANT_NAME #Name of the TMS instance to be created
TMS_CLIENT=$TENANT_NAME-tms-client
TMS_CLIENT_SECRET=pm5ecret

TMS_SERVICE_URL=https://$TMS_STATIC_ROUTE_HOST.$CF_BASE_DOMAIN
TENANT_CREDENTIAL_URL=https://$TENANT_SUBDOMAIN.$TMS_HOST_NAME.$CF_BASE_DOMAIN  #To POST client credentials


#Application stuff
SERVICE_NAME=All
AUTHORIZED_CLIENT_ID=$APP_CLIENT_ID
APP_CLIENT_ID=$TENANT_NAME-app-client
APP_CLIENT_SECRET=$KEYPASS #Generated secret

GRP_ROLE_PREFIX=edgemanager

SERVICE_INSTANCE_NAME_TO_BIND=em-logstash
SERVICE_NAME_TO_BIND=logstash-for-predix-platform

ZAC_CREDENTIALS_ADMIN=zac-tenancy-client
ZAC_CREDENTIALS_ADMIN_SECRET=zac-tenancy-client-secret

CREDENTIAL_AUTHORIZED_CLIENT_ID=zac-em-client

if [ -z "$TENANT_UAA_ADMIN" ]
  then
    TENANT_UAA_ADMIN=admin
    TENANT_UAA_ADMIN_SECRET=`head -c 500 /dev/urandom | LC_CTYPE=C tr -dc "a-zA-Z0-9-_" | head -c 15`
fi

if [ -z "$TENANT_UAA_URL" ]; then
    echo "******** Creating UAA ***********"
    cf cs $UAA_SERVICE_NAME $UAA_PLAN $TENANT_UAA_NAME -c '{"adminClientSecret":"'$TENANT_UAA_ADMIN_SECRET'"}'
    TENANT_UAA_GUID=$(cf service $TENANT_UAA_NAME --guid)
    TENANT_UAA_URL=https://$TENANT_UAA_GUID.$UAA_NAME_STAGING.$CF_BASE_DOMAIN

fi


TENANT_UAA_TOKEN_URL=$TENANT_UAA_URL/oauth/token


if [ "$CREATE_TIMESERIES" = 'y' ]; then
    echo "******** Creating Timeseries ***********"
    TIMESERIES_INSTANCE_NAME=timeseries-$TENANT_NAME
    cf cs $TIMESERIES_SERVICE_NAME $TIMESERIES_PLAN $TIMESERIES_INSTANCE_NAME -c '{"trustedIssuerIds":["'$TENANT_UAA_TOKEN_URL'"]}'
    TIME_SERIES_GUID=$(cf service $TIMESERIES_INSTANCE_NAME --guid)
elif [ ! -z "$TIMESERIES_INSTANCE_NAME" ]; then
    TIME_SERIES_GUID=$(cf service $TIMESERIES_INSTANCE_NAME --guid)
fi
echo "TIME_SERIES_GUID=$TIME_SERIES_GUID"


if [ "$CREATE_ASSET" = 'y' ]; then
    echo "******** Creating Asset instance ***********"
    ASSET_INSTANCE_NAME=asset-$TENANT_NAME
    echo "cf cs $ASSET_SERVICE_NAME $ASSET_PLAN $ASSET_INSTANCE_NAME -c '{"trustedIssuerIds":["$TENANT_UAA_TOKEN_URL"]}'"
    cf cs $ASSET_SERVICE_NAME $ASSET_PLAN $ASSET_INSTANCE_NAME -c '{"trustedIssuerIds":["'$TENANT_UAA_TOKEN_URL'"]}'
    ASSET_GUID=$(cf service $ASSET_INSTANCE_NAME --guid)
elif [ ! -z "$ASSET_INSTANCE_NAME" ]; then
    ASSET_GUID=$(cf service $ASSET_INSTANCE_NAME --guid)
fi
echo "ASSET_GUID=$ASSET_GUID"

echo "TENANT_UAA_TOKEN_URL=$TENANT_UAA_TOKEN_URL"

ZAC_UAA_TOKENURL=https://$UAA_HOST_NAME.$CF_BASE_DOMAIN/oauth/token
ZAC_UAA_URL=https://$UAA_HOST_NAME.$CF_BASE_DOMAIN
ZAC_UAA=https://$UAA_HOST_NAME.$CF_BASE_DOMAIN
echo "ZAC_UAA_TOKENURL=$ZAC_UAA_TOKENURL"


#Step 2. Create TMS service instance
echo "********  Creating TMS service instance ***********"
#echo "cf cs $TMS_SERVICE_NAME $TMS_PLAN $TMS_INSTANCE_NAME -c '{\"trustedIssuerIds\":[\"$TENANT_UAA_TOKEN_URL\",\"$ZAC_UAA_TOKENURL\"]}'"
#cf cs $TMS_SERVICE_NAME $TMS_PLAN $TMS_INSTANCE_NAME -c '{"trustedIssuerIds":["'$TENANT_UAA_TOKEN_URL'","'$ZAC_UAA_TOKENURL'"]}'

#echo $TMS_INSTANCE_NAME created successfully

#TMS_INSTANCE_ID=$(cf service $TMS_INSTANCE_NAME --guid)
TMS_INSTANCE_ID=9334fa04-559a-439c-92d1-6a17e5ca783f
echo TMS_INSTANCE_ID=$TMS_INSTANCE_ID

#Step 3. Create $TMS_CLIENT

echo "********  Creating TMS Client ***********"
 uaac target $TENANT_UAA_URL --skip-ssl-validation
 uaac token client get $TENANT_UAA_ADMIN -s $TENANT_UAA_ADMIN_SECRET
 echo "Creating a new client for TMS UAA $TENANT_UAA_NAME"
 echo "TMS CLIENT $TMS_CLIENT"

 uaac client add $TMS_CLIENT --authorities "tms.tms.read tms.tms.write tms.tenant.read tms.tenant.write $TMS_SERVICE_ID.zones.$TMS_INSTANCE_ID.user tms.tenant.credentials.read" -s $TMS_CLIENT_SECRET --authorized_grant_types client_credentials --name $TMS_CLIENT

# Get the token from the TMS UAA
uaac token client get $TMS_CLIENT -s $TMS_CLIENT_SECRET

# Step 4. Create tenant with services
 echo "********  Create a tenant entry into TMS ***********"
 echo "Add TMS tenant" $TENANT_NAME



  uaac curl -XPOST -d "{ \
      \"name\": \"$TENANT_NAME\", \
      \"templateData\": { \
        \"serviceInstances\": [ \
        { \
        \"serviceInstanceName\": \"$SERVICE_INSTANCE_NAME_TO_BIND\", \
        \"serviceName\": \"$SERVICE_NAME_TO_BIND\" \
      } \
        ], \
        \"type\": \"string\" \
      }, \
      \"templateName\": \"string\", \
      \"subdomain\":\"$TENANT_SUBDOMAIN\", \
      \"tenantUaa\":{ \
      \"tenantUaaList\": [ \
      \"$TENANT_UAA_NAME\"] \
       } \
    }" \
    -H "Content-Type: application/json" \
    -H "Predix-Zone-Id:$TMS_INSTANCE_ID" \
    $TMS_SERVICE_URL/v1/tenant

#Create a admin user on TENANT_UAA_NAME with privileges to update the client authorities


  echo "Creating a new client for Tenant UAA with admin privileges to update authorities on  $TENANT_UAA_NAME"
  uaac target $TENANT_UAA_URL --skip-ssl-validation

  uaac token client get $TENANT_UAA_ADMIN -s $TENANT_UAA_ADMIN_SECRET

  uaac group add $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Administrator
  uaac group add $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Operator
  uaac group add $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Technician
  uaac group add $GRP_ROLE_PREFIX.zones.$TENANT_NAME.TempRole
  uaac group add $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Enrollment
  uaac group add $APP_ID.zones.$TENANT_NAME.user

  uaac user add $TENANT_ADMIN --given_name $TENANT_ADMIN --email $TENANT_ADMIN_EMAIL -p $TENANT_ADMIN_PASS
  uaac member add $GRP_ROLE_PREFIX.zones.$TENANT_NAME.TempRole $TENANT_ADMIN
  uaac member add $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Administrator $TENANT_ADMIN
  uaac member add $APP_ID.zones.$TENANT_NAME.user $TENANT_ADMIN

  #Create application id $APP_CLIENT_ID. Tenant's admin provisions application client ids in the tenant's UAA

  uaac client add $APP_CLIENT_ID --authorities "tms.tenant.read  tms.tenant.credentials.read " -s $APP_CLIENT_SECRET --authorized_grant_types client_credentials --name $APP_CLIENT_ID

  #Update the authorities after the instance has been provisioned
  echo "Updating the authorities of $APP_CLIENT_ID for the new service"


  uaac token client get $TENANT_UAA_ADMIN  -s $TENANT_UAA_ADMIN_SECRET


  #Temporarily add clients.admin and Enrollment to give this client permission to add devices until we create an enrollment client
  uaac client update $APP_CLIENT_ID  --redirect_uri "https://$TENANT_NAME.$EDGEMANAGER_BASE_DOMAIN" --autoapprove "openid $APP_ID.zones.$TENANT_NAME.user $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Administrator $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Operator $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Technician $GRP_ROLE_PREFIX.zones.$TENANT_NAME.TempRole $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Enrollment" --scope "uaa.none openid $APP_ID.zones.$TENANT_NAME.user $PROXIMETRY_APP_ID.zones.$TENANT_NAME.user $GRP_ROLE_PREFIX.zones.$TENANT_NAME.TempRole $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Administrator $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Operator $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Technician" --authorized_grant_types "authorization_code client_credentials password refresh_token" --authorities "$ASSET_SERVICE_NAME.zones.$ASSET_GUID.user tms.tenant.read  tms.tenant.credentials.read $TMS_SERVICE_ID.zones.$TMS_INSTANCE_ID.user $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Administrator $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Operator $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Technician openid  $APP_ID.zones.$TENANT_NAME.user scim.write scim.read uaa.resource $GRP_ROLE_PREFIX.zones.$TENANT_NAME.Enrollment password.write clients.admin $PROXIMETRY_APP_ID.zones.$TENANT_NAME.user"


  echo "Add client credentials"

  uaac target $ZAC_UAA_URL

  uaac token client get $ZAC_CREDENTIALS_ADMIN -s $ZAC_CREDENTIALS_ADMIN_SECRET

  uaac curl -XPOST -d "[ \
  { \
    \"authorizedClientId\": \"$CREDENTIAL_AUTHORIZED_CLIENT_ID\", \
    \"clientId\": \"$APP_CLIENT_ID\", \
    \"clientSecret\": \"$APP_CLIENT_SECRET\", \
    \"issuer\": \"$TENANT_UAA_URL\", \
    \"serviceName\": \"$SERVICE_NAME\" \
  } \
]" \
-H "Content-Type: application/json" \
$TENANT_CREDENTIAL_URL/v1/client-credentials

echo "client credentials added successfully"


uaac target https://$UAA_NAME_STAGING.$CF_BASE_DOMAIN
uaac token client get $ZAC_WRITE_CLIENT_ID -s $ZAC_WRITE_CLIENT_SECRET
#uaac token decode

#Provision ZAC with the app id's (predix-edge) trusted issuer
echo "****************Provision ZAC with the app id's (predix-edge) trusted issuer****************"
uaac curl -XPUT -d "{ \
  \"trustedIssuerIds\": [ \
     \"$TENANT_UAA_TOKEN_URL\" , \
     \"$ZAC_UAA_TOKENURL\" \
  ] \
}" \
    -H "Content-Type: application/json" \
    $ZAC_REGISTRATION_URL/$APP_ID/$TENANT_NAME

#Provision ZAC with the proximetry app id's trusted issuer
uaac curl -XPUT -d "{ \
  \"trustedIssuerIds\": [ \
     \"$TENANT_UAA_TOKEN_URL\" , \
     \"$ZAC_UAA_TOKENURL\" \
  ] \
}" \
    -H "Content-Type: application/json" \
    $ZAC_REGISTRATION_URL/$PROXIMETRY_APP_ID/$TENANT_NAME


#Provision tenant org guid and timeseries zoneid and prosyst key type to edgemanager tenant service
ORG_GUID=$(cf org $ORG_NAME --guid)

uaac target $EDGEMANAGER_DEFAULT_UAA
uaac token client get $EDGEMANAGER_TENANT_CLIENT_ID -s $EDGEMANAGER_TENANT_CLIENT_SECRET

uaac curl -XPOST -d "{ \
\"tenantName\": \"$TENANT_NAME\", \
\"subDomain\": \"$TENANT_NAME\", \
\"organizationId\": \"$ORG_GUID\", \
\"trustedIssuerIds\": [\"$TENANT_UAA_TOKEN_URL\"], \
\"serviceInstances\": [{ \
\"serviceName\": \"timeseries\", \
\"serviceInstanceName\": \"$TIME_SERIES_INSTANCE_NAME\", \
\"serviceInstanceId\": \"$TIME_SERIES_GUID\" \
}, { \
\"serviceName\": \"prosyst\", \
\"serviceInstanceName\": \"\", \
\"serviceInstanceId\": \"$PROSYST_KEY_TYPE\" \
}, { \
\"serviceName\": \"predix-asset\", \
\"serviceInstanceName\": \"$ASSET_INSTANCE_NAME\", \
\"serviceInstanceId\": \"$ASSET_GUID\" \
}
] \
}" "$EDGEMANAGER_TENANT_URL" -H "Content-Type: application/json"

#Upload prosyst key package to app repo
uaac curl -XPOST "${EDGEMANAGER_TENANT_URL}/${TENANT_NAME}/prosyst" -H "Content-Type: application/json"


echo "Creating root group in asset"
uaac target $TENANT_UAA_URL
uaac token client get $APP_CLIENT_ID -s $APP_CLIENT_SECRET
output=$(uaac curl -XPOST -d "[{\"uri\":\"/groups/GR_0\", \"id\":\"GR_0\", \"name\":\"ROOT\"}]" "$ASSET_URL/groups" -H "Predix-Zone-Id: $ASSET_GUID" -H "Content-Type: application/json" | grep "204 No Content")
#make sure HTTP status 204 is returned
if [ "$output" != "204 No Content" ];  then false ; fi

echo "Setting up default device models for tenant"
output=$(uaac curl -X POST -H "Content-Type: application/json" "https://$TENANT_SUBDOMAIN.$EDGEMANAGER_BASE_DOMAIN/svc/device/v1/device-mgmt/system_models" | grep "204 No Content")
#make sure HTTP status 204 is returned
if [ "$output" != "204 No Content" ];  then false ; fi

# echo "Tenant provison finished for $TENANT_NAME. Writing the following values to file $TENANT_NAME.out"
# echo Tenant name:        $TENANT_NAME
# echo Tenant UAA url:     $TENANT_UAA_URL
# echo TMS instance id:    $TMS_INSTANCE_ID
# echo Tenant admin user:  $TENANT_NAME-admin
# echo Tenant admin pass:  chang3m3
# echo Application client: $APP_CLIENT_ID
# echo App client secret:  $APP_CLIENT_SECRET
# echo Tenant uaa admin:   $TENANT_UAA_ADMIN
# echo Tenant uaa admin secret: $TENANT_UAA_ADMIN_SECRET
# echo Timeseries instance id:  $TIME_SERIES_GUID
# echo Asset instance id:  $ASSET_GUID
# echo EdgeManager url:    https://$TENANT_NAME.$EDGEMANAGER_BASE_DOMAIN

#Write important values to file
write_to_output
