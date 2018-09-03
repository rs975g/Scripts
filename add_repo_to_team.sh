#!/bin/bash

protocol='https://'
org_flag="false"
wrong_arg="false"
bold=$(tput bold)
normal=$(tput sgr0)
user_passed="false"
pass_passed="false"
url="https://${user}:${password}@api.github.com/orgs/PredixDev/repos?per_page=100"

while getopts ":u:p:" opt; do
  case "$opt" in
  	#find username
	u)
		user="$OPTARG"
		user_passed="true"
	;;
	#find password
	p)
		password="$OPTARG"
		pass_passed="true"
	;;
	# ? means invalid flag was passed.
	\?)
    	echo "Invalid option: ${bold}-$OPTARG${normal}" >&2
    	exit 1
    ;;
    :)
		echo "the -$OPTARG option requires an argument."
		exit 1
	;;
  esac
done

function get_repo_list () {
	repo_list=($(curl ${protocol}${user}:${password}@api.github.com/orgs/PredixDev/repos?per_page=100 | grep '"clone_url": ' | sed 's/"clone_url"://;s/.$//;s/^ *//'| cut -f5 -d / | sed 's/\..*//g' | grep -E '^px-|generator|predix-seed'))
}
function add_repo_to_team () {
	for repo in ${repo_list[@]}; do
		add_repo=($(curl -X PUT ${protocol}${user}:${password}@api.github.com/teams/1807621/repos/PredixDev/${repo}))
		echo "added ${repo} to read only team"
	done
}
function main () {
	get_repo_list
	add_repo_to_team
}

main

#PredixCollaborators id is 1807621
