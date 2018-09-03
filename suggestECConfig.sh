#!/bin/bash

function error {
  printf "\e[7;49;31;82m $1 \e[0m"
  exit 1
}

function check_internet() {
  echo ""
  echo "Checking internet connection..."
  curl "http://google.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy"
    echo "If you are behind a corporate proxy, set the 'http_proxy' and 'https_proxy' environment variables."
    exit 1
  fi
  echo "OK"
}

function incorrect_args(){
  echo "Usage:
        $0 -e <EC Service Name> -c <Client ID> -s <Client Secret> -d <Refresh token duration> -r <Resource Host> -p <Resource Port#> -l <Local Port>  [-x <Proxy URL> -z <Flag to push to Predix>]"
}

function get_args(){
  while getopts "e:c:s:d:r:p:l:x:z:" opt; do
    case $opt in
      e)
      ec_instace_name=$OPTARG
      ;;
      c)
      cid=$OPTARG
      ;;
      s)
      csc=$OPTARG
      ;;
      d)
      dur=$OPTARG
      ;;
      r)
      rht=$OPTARG
      ;;
      p)
      rpt=$OPTARG
      ;;
      l)
      lpt=$OPTARG
      ;;
      x)
      pxy=$OPTARG
      ;;
      z)
      cfpush=$OPTARG
      ;;

      \?)
      echo "Invalid option -$OPTARG"
      incorrect_args
      ;;
    esac
  done
}

function validate_inputs(){
  if [ -z "$ec_instace_name" ]; then
     incorrect_args
     error "EC service name -ec is required."
  fi

  if [ -z "$cid" ]; then
    incorrect_args
    error "Cliend Id -cid is required."

  fi

  if [ -z "$csc" ]; then
    incorrect_args
    error "Client Secret -csc is required."
  fi

  if [ -z "$dur" ]; then
    incorrect_args
    error "Refresh token duration -dur is required."
  fi

  if [ -z "$rht" ]; then
    incorrect_args
    error "Resource Host -rht is required."
  fi

  if [ -z "$rpt" ]; then
     incorrect_args
     error "Resource Port# -rpt is required."
  fi

  if [ -z "$lpt" ]; then
     incorrect_args
     error "Local Port# -lpt is required."
  fi

  if [ -z "$pxy" ]; then
     pxy=""
  else
    pxy="-pxy $pxy"
  fi

  if ! [[ "$cfpush" =~ ^[yn]$ ]]; then
      incorrect_args
      error "Push to Predix -z must be followed by either y or n."
  fi
}

get_args $*
validate_inputs

check_internet

target=$(cf t)

# Setting urls based on cf t
if [[ $target == *"FAILED"* ]];
then
  error "FAIL ----> Not logged in to CF, please do \"cf login\""
elif [[ $target == *"https://api.system.aws-usw02-pr.ice.predix.io"* ]];
then
  #echo "It's BASIC!";
  urlSuffixUrl="run.aws-usw02-pr.ice.predix.io"
elif [[ $target == *"https://api.system.asv-pr.ice.predix.io"* ]];
then
  #echo "It's SELECT!";
  urlSuffixUrl="run.asv-pr.ice.predix.io"
else
  error "Unknown environment"
fi

result_sc_creation=$(cf create-service-key $ec_instace_name test-key-ec)
if [[ $result_sc_creation == *"FAILED"* ]];
then
  error "FAIL ---->  Fail to create the service key \"cf create-service-key $ec_instace_name test-key-ec\", possible reasons: wrong service name or service instance not supported"
fi
echo "Getting EC data from service-key "
raw_ec_data=$(cf service-key $ec_instace_name test-key-ec | tail -n +2 | jq .)
#zon=$(echo $raw_ec_data | jq -r '."ec-info".sid ')
zon=$(echo $raw_ec_data | jq -r '.zone."http-header-value"')

if [ -z "$zon" ] || [[ $zon == *"null"* ]]; then
   error "Not able to get the Predix-Zone-Id from the service key. \"cf service-key $ec_instace_name test-key-ec\""
fi
sst=$(echo $raw_ec_data | jq -r '."service-uri"' | grep -o 'https://[^/]*')
adm_tkn=$(echo $raw_ec_data | jq -r '."ec-info"."adm_tkn" ')
id_1=$(echo $raw_ec_data | jq -r '."ec-info"."ids"[0] ')
id_2=$(echo $raw_ec_data | jq -r '."ec-info"."ids"[1] ')
oa2=$(echo $raw_ec_data | jq -r '."ec-info"."trustedIssuerIds"[0] ')

echo "Creating your Gateway agent"
mkdir gateway-${zon}
cat > ./gateway-${zon}/ec.sh << EOL
#!/bin/bash

sleep 5
./ecagent_linux_sys -mod "gateway" -lpt "\${PORT}" -zon "$zon" -sst "$sst" -tkn "$adm_tkn" -dbg

EOL

cat > ./gateway-${zon}/manifest.yml << EOL
applications:
  - name: gateway-${zon}
    memory: 128M
    instances: 1
    stack: cflinuxfs2
    path: .
    command: bash ./ec.sh
    buildpack: https://github.com/cloudfoundry/binary-buildpack.git
EOL

wget -qO- https://github.com/Enterprise-connect/ec-sdk/raw/dist/dist/ecagent_linux_sys.tar.gz | tar xvz -C ./gateway-${zon}/

if [ "$cfpush" = "y" ]; then
  echo "Pushing Gateway to Predix"
  cd ./gateway-${zon}
  cf p --no-start
  #cf enable-diego gateway-${zon}
  cf start gateway-${zon}
  cd ..
fi
###### GET THE GATEWAY URL
gateway_url="gateway-${zon}.${urlSuffixUrl}"
hst="wss://${gateway_url}/agent"

echo "Creating your Server agent"
mkdir server-${zon}
cat > ./server-${zon}/ec.sh << EOL
#!/bin/bash

sleep 5
./ecagent_linux_sys -mod "server" -zon "$zon" -grp "$zon" -sst "$sst" -aid "$id_1" -cid "$cid" -csc "$csc" -dur "$dur" -hst "$hst" -oa2 "$oa2" -rht "$rht" -rpt "$rpt" -hca "\${PORT}"

EOL

cat > ./server-${zon}/manifest.yml << EOL
applications:
  - name: server-${zon}
    memory: 128M
    instances: 1
    stack: cflinuxfs2
    path: .
    command: bash ./ec.sh
    buildpack: https://github.com/cloudfoundry/binary-buildpack.git
EOL
wget -qO- https://github.com/Enterprise-connect/ec-sdk/raw/dist/dist/ecagent_linux_sys.tar.gz | tar xvz -C ./server-${zon}/
if [ "$cfpush" = "y" ]; then
  echo "Pushing Server to Predix"
  cd ./server-${zon}
  cf p --no-start
  #cf enable-diego server-${zon}
  cf start server-${zon}
  cd ..
fi

echo "Creating your Client agent"
mkdir client-${zon}
cat > ./client-${zon}/ec.sh << EOL
#!/bin/bash
./ecagent_darwin_sys -mod "client" -aid "$id_2" -tid "$id_1" -hst "$hst" -lpt "$lpt" -cid "$cid" -csc "$csc" -oa2 "$oa2" -dur "$dur" -grp "$zon" $pxy
EOL

wget -qO- https://github.com/Enterprise-connect/ec-sdk/raw/dist/dist/ecagent_darwin_sys.tar.gz | tar xvz -C ./client-${zon}/
wget -qO- https://github.com/Enterprise-connect/ec-sdk/raw/dist/dist/ecagent_linux_sys.tar.gz | tar xvz -C ./client-${zon}/

echo "Following values were used to create your EC configuration"
echo "EC instance name: ${ec_instace_name}"
echo "rht: $rht"
echo "rpt: $rpt"
echo "lpt: $lpt"
echo "zon: $zon"
echo "hst: $hst"
echo "sst: $sst"
echo "oa2: $oa2"
echo "cid: $cid"
echo "csc: $csc"
echo "dur: $dur"
echo "adm_tkn: $adm_tkn"
echo "Server Id: $id_1"
echo "Client Id: $id_2"
echo "$pxy"
echo "++++++++++++++++++++++++++++++++++++++++ Files created ++++++++++++++++++"
echo "GATEWAY"
echo "./gateway-${zon}/"
ls -lthr ./gateway-${zon}/
echo "SERVER"
echo "./server-${zon}/"
ls -lthr ./server-${zon}/
echo "CLIENT"
echo "./client-${zon}/"
ls -lthr ./client-${zon}/
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Follow the next steps to start your client:"
echo "cd ./client-${zon}"
echo "chmod +x ec.sh"
echo "./ec.sh"
echo "Or execute your client with the following parameters"
echo "./ecagent_darwin_sys -mod client -aid $id_2 -tid $id_1 -hst $hst -lpt $lpt -cid $cid -csc $csc -oa2 $oa2 -dur $dur -grp $zon $pxy"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
