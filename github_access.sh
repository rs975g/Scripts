#!/bin/bash
#This script adds collaborators to github 

#set our vars first
protocol='https://'
org_flag="false"
wrong_arg="false"
bold=$(tput bold)
normal=$(tput sgr0)
user_passed="false"
pass_passed="false"
url="https://${user}:${password}@api.github.com/orgs/PredixDev/repos?per_page=100"
# parameters passed:
# 1) Type of addition -t (team or collaborator)
# 2) if team, Name of team is required -n
while getopts ":u:p:t:" opt; do
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
	#t stands for Type: available options are team or collaborator
	t)
		add_type=$OPTARG
		type_passed="true"
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

function get_user_pass () {
	if [[ -z $user ]]
		then
		echo "${bold}to skip this step next time, enter the username using the -u flag${normal}"
		read -p "Please enter the github admin user: " user
	fi

	if [[ -z $password ]]
		then
		echo "${bold}to skip this step next time, enter the password using the -p flag${normal}"
		echo "Please enter the github admin password: "
		read -s password
	fi
}
function get_repo_list () {
    repo_list=($(curl ${protocol}${user}:${password}@api.github.com/orgs/PredixDev/repos?per_page=100 | grep '"clone_url": ' | sed 's/"clone_url"://;s/.$//;s/^ *//'| cut -f5 -d / | sed 's/\..*//g'))
    repo_list2=($(curl "${protocol}${user}:${password}@api.github.com/orgs/PredixDev/repos?per_page=100&page=2" | grep '"clone_url": ' | sed 's/"clone_url"://;s/.$//;s/^ *//'| cut -f5 -d / | sed 's/\..*//g'))
    repo_list=("${repo_list[@]}" "${repo_list2[@]}")
}

function find_team_id () {
	index_id=$(( $selected_team*2-1))
	team_id=${team_names[${index_id}]}
}

function team_repos () {
	find_team_id
	for repo in ${repo_list[@]}; do
    if [[ ${action} = "add" ]]
      then
        status=($(curl -X PUT ${protocol}${user}:${password}@api.github.com/teams/${team_id}/repos/PredixDev/${repo}))
    elif [[ ${action} = "remove" ]]
      then
        status=($(curl -X DELETE ${protocol}${user}:${password}@api.github.com/teams/${team_id}/repos/PredixDev/${repo}))
    fi
		echo "${method} team - repo = ${repo} and team_id = ${team_id}"
	done
}

function collaborator_repos () {

  for collection in ${repo_list[@]}; do
    for repo in ${collection[@]}; do
      if [[ ${action} = "add" ]]
        then
          status=($(curl -X PUT -d '{"permission": "pull"}'  ${protocol}${user}:${password}@api.github.com/repos/PredixDev/${repo}/collaborators/${collaborator_github_user}))
      elif [[ ${action} = "remove" ]]
        then
          status=($(curl -X DELETE ${protocol}${user}:${password}@api.github.com/repos/PredixDev/${repo}/collaborators/${collaborator_github_user}))
      fi
      echo "repo is ${repo} and collaborator_github_user is ${collaborator_github_user}."
  	done
  done
}


function work_summary () {
  repo_collections=(  ${adoption_repos[@]} ${extra_repos[@]} )
  echo "Repo List -- ${#repo_list[*]} total"
  printf '%s\n' "${repo_collections[@]}" | column -c 150
}


function single_or_many () {
	if [[ ${collab_type} = "single" ]]
		then
      collaborator_repos
	elif [[ ${collab_type} = "many" ]];
		then
  		read -a collab_list < ${csv_file}
  		collab_list=($(printf -- '%s' "${collab_list[@]}" | sed 's/,/ /g'))
  		for c_user in ${collab_list[@]}; do
  			collaborator_github_user=${c_user}
        collaborator_repos
  		done
	fi
}

function get_team_names () {
	team_names=($(curl ${protocol}${user}:${password}@api.github.com/orgs/PredixDev/teams?per_page=100  | grep -E 'id|name' | sed 's,"name": ",,; s,"id":,,;s/"//;s/,//'| sed '/^$/d;s/[[:blank:]]//g'))
	local index=0
	for i in ${team_names[@]}; do
		check=$(($index%2))
	    if [[  ${check} -eq 0 ]]; then
	        displayArray+="${team_names[${index}]} "
	    fi
	    local index=$((${index}+1))
	done
}

function add_or_delete () {
  echo "${bold}would you like to add or remove a person?:${normal}"
  add_remove[0]="Add"
  add_remove[1]="Remove"

  select action in ${add_remove[@]}; do
    case ${action} in
      "Add")
        action="add"
        break
      ;;
      "Remove")
        action="remove"
        break
      ;;
    esac
  done
}

function team_or_collaborator () {
	echo "${bold}Please select the type of addition you'd like to make:${normal}"
	add_options[0]="Collaborator"
	add_options[1]="Team"
	add_options[2]="Quit"

	select add_option in ${add_options[@]}; do
		case ${add_option} in
			"Team")
				type_passed="team"
				get_user_pass
				# get the team names into an array
				get_team_names
				#and ask the user which team he'd like to add to all repos
				select team in ${displayArray[@]}; do
					selected_team=$REPLY
					break 2
				done
			;;

			"Collaborator")
				#collaborator
				type_passed="collaborator"
				collaborator_type="Single Many"
				echo "${bold}Choose whether you'd like to add a Single collaborator or Many:${normal}"
				select c_type in ${collaborator_type}; do
					case ${c_type} in
						"Single")
							read -p "${bold}what is the collaborator's github username?${normal} " collaborator_github_user
							collab_type="single"
							break 2
						;;
						"Many")
							collab_type="many"
							echo "${bold}Please select the CSV file. Please note it must be in the same directory as the script.${normal} "
							select FILENAME in *; do
								csv_file=$FILENAME
								break 3
							done
						;;
					esac
				done
			;;

			"Quit")
				#quit. duh.
				exit 1
			;;
		esac
	done
}

function main () {
  add_or_delete
	team_or_collaborator
	get_user_pass
	get_repo_list
	case $type_passed in
		"team")
      			team_repos
		;;
		"collaborator")
      			single_or_many
		;;
	esac
	work_summary
}
main
