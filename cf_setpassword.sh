#!/bin/sh
#temporary security format


user_ids=()

#rm ~/Desktop/passwords.txt
for i in "${user_ids[@]}"; do echo $i; done;
echo "-------------------------"
for i in "${user_ids[@]}";
do
  password=`openssl rand -base64 9`
  k=69!
  uaac password set $i -p $password$k
  echo "New Password for $i is $password$k"
  echo "------------------------"
done
