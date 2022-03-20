#!/bin/bash

NONE='\033[00m'; RED='\033[01;31m'; GREEN='\033[01;32m'; BOLD='\033[1m';

echo -e "\n${GREEN}${BOLD}CYBER RANGE!${NONE}\n"
sleep 0

function checkIfJqIsAvailable () {
	if ! [[ -x "$(command -v jq)" ]]
	then
		echo -e "${RED}Error${NONE}: JQ could not be found." >&2
		exit 1
	fi
}

function dataExpose () {
	echo -e "The number of instances: ${RED}$instancesCount${NONE}"
	echo -e "Maximum amout of memory (MB) for one instance: ${RED}$maxRAM${NONE}"
	echo -e "Maximum amount of storage (MB) for one instance: ${RED}$maxStorage${NONE}"
	echo -e "There will be only instances with Windows OS: ${RED}$onlyWindows${NONE}"
	echo -e "There will be only instances with Linux OS: ${RED}$onlyLinux${NONE}"
	echo -e "The number of unique CVEs: ${RED}$cveCount${NONE}"
};

function isOnlyWindows () {
	local arr=("$@")
	for i in "${arr[@]}"
	do
		if [[ $i == "linux" ]]
		then
			false
			#CIA KAZKA REIKIA SUMASTYTI
		fi
	done
	true
}

function username () {
	echo "admin"
}

function password () {
	pass=$(cat ./passwords.txt | head -n $(echo $RANDOM | head -c 2) | tail -n 1)
	echo $pass
};

function main () {
	#Data gathering
		data=$(cat ./data.json)
		cveList=$(cat ./cve_list.json)
		instancesCount=$(echo $data | jq .instancesCount)
		maxRAM=$(echo $data | jq .maxRam)
		maxStorage=$(echo $data | jq .maxStorage)
		onlyWindows=$(echo $data | jq .onlyWindows)
		onlyLinux=$(echo $data | jq .onlyLinux)
		cveCount=$(echo $data | jq .cve[].id | wc -l)
		cveCount2=$(echo $cveList | jq .cve[].id | wc -l)
	#Data expose
		dataExpose

		declare -A instances
		declare -A allOSes
		for (( i=0; i<$cveCount; i++ ))
		do
			for (( k=0; k<$cveCount2; k++ ))
			do
				if [[ "$(echo $data | jq .cve[$i].id)" == "$(echo $cveList | jq .cve[$k].id)" ]]
				then
					instances[$i,'id']=$(echo $cveList | jq -r .cve[$k].id)
                        		instances[$i,'os']=$(echo $cveList | jq -r .cve[$k].os)
					instances[$i,'version']=$(echo $cveList | jq -r .cve[$k].version)
					instances[$i,'user']=$(username)
					instances[$i,'pass']=$(password)
					allOSes[$i]=${instances[$i,'os']}
				fi
			done

			j=$( expr $i + 1 )
			echo -e "\n -------------------------------"
			echo -e "| $j. Instance\t\t\t|"
			echo -e "|       CVE: ${RED}${instances[$i,'id']}${NONE}\t|"
			echo -e "|       OS: ${RED}${instances[$i,'os']}${NONE}\t\t|"
			echo -e "|       Version: ${RED}${instances[$i,'version']}${NONE}\t\t|"
			echo -e "|       Username: ${RED}${instances[$i,'user']}${NONE}\t\t|"
			echo -e "|       Password: ${RED}${instances[$i,'pass']}${NONE}   \t|"
			echo -e " -------------------------------"
		done
		isOnlyWindows "${allOSes[@]}"		
};

checkIfJqIsAvailable
main
