#!/bin/bash


while read line
do
	cf curl /v2/organizations/$line >> Org_Name.txt
done< org_id.txt
