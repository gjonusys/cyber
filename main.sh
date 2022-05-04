#!/bin/bash

NONE='\033[00m'; RED='\033[01;31m'; GREEN='\033[01;32m'; BOLD='\033[1m';

echo -e "\n${GREEN}${BOLD}CYBER RANGE!${NONE}\n"
sleep 0

function checkIfJqIsAvailable () {
        if ! [[ -x "$(command -v jq)" ]]
        then
                echo -e "${RED}Error${NONE}: JQ could not be found. Wait a little bit..." >&2
                apt-get install jq -y
        fi
}

function dataExpose () {
        echo -e "The number of instances: ${RED}$instancesCount${NONE}"
        echo -e "Maximum amout of memory (MB) for one instance: ${RED}$maxRAM${NONE}"
        echo -e "Maximum amount of storage (MB) for one instance: ${RED}$maxStorage${NONE}"
        echo -e "There will be only instances with Windows OS: ${RED}$onlyWindows${NONE}"
        echo -e "There will be only instances with Linux OS: ${RED}$onlyLinux${NONE}"
        echo -e "The number of unique CVEs: ${RED}$cveCount${NONE}"
        echo ""
};

function areFilesAvailable () {
        echo -e "\t[Decision] Are all files available?" >$(tty)
        if [[ -f 'data.json' ]]
        then
                if [[ -f 'cve_list.json' ]]
                then
                        if [[ -f 'passwords.txt' ]]
                        then
                                echo -e "\t[LogicLink] Yes" >$(tty)
                                echo "0" && return 0
                        else
                                echo -e "\t[LogicLink] No" >$(tty)
                                fileIsMissing "passwords.txt" >$(tty)
                                echo "3" && return 3
                        fi
                else
                        echo -e "\t[LogicLink] No" >$(tty)
                        fileIsMissing "cve_list.json" >$(tty)
                        echo "2" && return 2
                fi
        else
                echo -e "\t[LogicLink] No" >$(tty)
                fileIsMissing "data.json" >$(tty)
                echo "1" && return 1
        fi
};

function fileIsMissing () {
        echo -e "\n${RED}The program cannot find file named \"$1\". Please start the program after You fix the problem.${NONE}\n\nExiting..." >$(tty) && sleep 3 && exit 1
};

function isJqInstalled () {
        echo -e "$1\t[Decision] Is JQ installed?" >$(tty)
        if [[ -x "$(command -v jq)" ]]
        then
                echo -e "$1\t{LogicLink] Yes" >$(tty)
                echo "0" && return 0
        else
                echo -e "$1\t[LogicLink] No" >$(tty)
                echo "1" && return 1
        fi
};

function wantToInstall () {
        echo -e "\t[Decision] Does the user want to install JQ?" >$(tty)
        read -p "$(echo -e "\t")[UserInput] y/n? " userInput >$(tty)
        if [[ "$userInput" = 'y' ]]
        then
                echo -e "\t[LogicLink] Yes" >$(tty)
                echo "0" && return 0
        elif [[ "$userInput" = 'n' ]]
        then
                echo -e "\t[LogicLink] No" >$(tty)
                echo "1" && return 1
        else
                echo -e "\t[LogicLink] No" >$(tty)
                echo "2" && return 2
        fi
};

function installJq () {
        echo -e "\t[AutomaticLink] Transition\n\t[Stage] ${BOLD}Install JQ${NONE}\n\t\t[Decision] Is JQ being installed?\n\t\t[LogicLink] Yes" >$(tty)
        sudo apt-get install jq -y >>/dev/null
        sleep 20
        if (( $(isJqInstalled "\t") == "0" ))
        then
                echo -e "\t[Stage] ${BOLD}JQ is installed${NONE}" >$(tty)
                echo "0" && return 0
        else
                echo "1" && return 1
        fi
};

function isOnlyWindows () {
        echo -e "\t[Decision] Is only Windows?" >&$(tty)
        local arr=("$@")
        for i in "${arr[@]}"
        do
                if [[ "$i" = 'linux' ]]
                then
                        echo -e "\t[LogicLink] No" >$(tty)
                        echo "1" && return 1
                fi
        done
        echo -e "\t[LogicLink] Yes" >$(tty)
        echo "0" && return 0
};

function isOnlyLinux () {
        echo -e "\t[Decision] Is only Linux?" >&$(tty)
        local arr=("$@")
        for i in "${arr[@]}";
        do
                if [[ "$i" = 'windows' ]]
                then
                        echo -e "\t[LogicLink] No" >$(tty)
                        echo "1" && return 1
                fi
        done
        echo -e "\t[LogicLink] Yes" >$(tty)
        echo "0" && return 0

};

function isThereANeedForDifferentOS () {
        echo -e "\t[Decision] Is there a need for different OS?" >&$(tty)
        local result=$(echo $1)
        if [[ "$1" = 'Yes' ]]
        then
                echo -e "\t[LogicLink] Yes" >$(tty)
                echo "0" && return 0
        else
                echo -e "\t[LogicLink] No" >$(tty)
                echo "1" && return 1
        fi
};

function willBeEnoughCves () {
        echo -e "\t[Decision] Will be enough CVEs for all VMs?" >&$(tty)
        local result=$(echo $(( $1 * 100 / $2 )))
        if [[ "$result" -ge 50 ]]
        then
                echo -e "\t[LogicLink] Yes" >$(tty)
                echo "0" && return 0
        else
                echo -e "\t[LogicLink] No" >$(tty)
                echo "1" && return 1
        fi
};

function isThereCveFor () {
        echo -e "\t\t[Decision] Is there a CVE for $1?" >$(tty)
        local vm_purpose=$1
        local vm_os=$2
        shift
        shift
        local arr=("$@")
        for i in "${arr[@]}"
        do
                if [[ "$i" = "$vm_os" ]]
                then
                        echo -e "\t\t[LogicLink] Yes" >$(tty)
                        echo "0" && return 0
                fi
        done
        echo -e "\t\t[Decision] No" >$(tty)
        echo "1" && return 1
};

function moreThanOneCveFor () {
        echo -e "\t\t[Decision] Are there more than one unique CVE for $1?" >$(tty)
        local vm_purpose=$1
        local vm_os=$2
        local count=0
        shift
        shift
        local arr=("$@")
        for i in "${arr[@]}"
        do
                if [[ "$i" = "$vm_os" ]]
                then
                        count=$((count+1));
                fi
        done
        if [[ "$count" -gt 1 ]]
        then
                echo -e "\t\t[LogicLink] Yes" >$(tty)
                echo "0" & return 0
        elif [[ "$count" -eq 1 ]]
        then
                echo -e "\t\t[LogicLink] No" >$(tty)
                echo "1" && return 1
        else
                echo "2" && return 2
        fi
};

function takeThatOnlyAvailableCveFromUserInput () {
        echo -e "\t\t[Action] Assign a CVE for $1 from the only one input" >$(tty)
        local vm_os=$2
        local userCveCount=$3
        local allCveCount=$4
        for (( i=0; i<$userCveCount; i++ ))
        do
                varUserCveId=$(cat ./data.json | jq -r .cve[$i].id)
                for (( j=0; j<$allCveCount; j++ ))
                do
                        varCveId=$(cat ./cve_list.json | jq -r .cve[$j].id)
                        varCveVersion=$(cat ./cve_list.json | jq -r .cve[$j].version)
                        if [[ "$varUserCveId" = "$varCveId" ]] && [[ "$vm_os" = "$varCveVersion" ]]
                        then
                                echo "$varUserCveId" && return 0
                        fi
                done
        done
        echo "1" && return 1
};

function isThereANeedFor () {
        echo -e "\t\t[Decision] Is there a need for $1?" >$(tty)
        local point=$2
        local answer=$(cat ./data.json | jq -r .$point)
        if [[ "$answer" = 'true' ]]
        then
                echo -e "\t\t[LogicLink] Yes" >$(tty)
                echo "0" && return 0
        elif [[ "$answer" = 'false' ]]
        then
                echo -e "\t\t[LogicLink] No" >$(tty)
                echo "1" && return 1
        else
                echo -e "\t\t[LogicLink] Unknown" >$(tty)
                echo "2" && return 2
        fi
};

function takeRandomCveFor () {
        echo -e "\t\t[Action] Assign a random CVE for $1" >$(tty)
        local vm_version=$2
        local allCveCount=$3
        local count=0
        declare -A goodCves
        for (( i=0; i<$allCveCount; i++ ))
        do
                varCveVersion=$(cat ./cve_list.json | jq -r .cve[$i].version)
                if [[ "$vm_version" = "$varCveVersion" ]]
                then
                        varCveId=$(cat ./cve_list.json | jq -r .cve[$i].id)
                        goodCves[$count]=$varCveId
                        count=$((count+1))
                fi
        done
        position=$(( ($RANDOM % 3) ))
        if [ ! -z "${goodCves[$position]}" ]
        then
                echo "${goodCves[$position]}" && return 0
        else
                echo "1" && return 1
        fi
};

function username () {
        echo "admin"
};

function password () {
        pass=$(cat ./passwords.txt | head -n $(echo $RANDOM | head -c 2) | tail -n 1)
        echo $pass
};

function main () {
        #Logic
                echo -e "[Process] Main process \t($(date))"
                echo -e "[Stage] The user \"$USER\" has started the process"
                echo -e "[AutomaticLink] Transition"
                echo -e "[LinkedProcess] ${BOLD}Requirements check START${NONE}"
                if (( $(areFilesAvailable) == "0" ))
                then
                        if (( $(isJqInstalled "") == "0" ))
                        then
                                echo -e "\t[AutomaticLink] Transition\n\t[Stage] Requirements are appropriate\n[LinkedProcess] ${BOLD}Requirements check END${NONE}"
                        else
                                if (( $(wantToInstall) == "0" ))
                                then
                                        if (( $(installJq) == "0" ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n\t[Stage] Requirements are appropriate\n[LinkedProcess] ${BOLD}Requirements check END${NONE}"
                                        else
                                                echo -e "${RED}Install JQ manually and restart the program.${NONE}" && exit 1
                                        fi
                                else
                                        echo -e "${RED}Install JQ manually and restart the program.${NONE}" && exit 1
                                fi
                        fi
                else
                        exit 1
                fi
                echo -e "[AutomaticLink] Transition"

        #Data gathering
                data=$(cat ./data.json)
                cveList=$(cat ./cve_list.json)
                instancesCount=$(echo $data | jq .instancesCount)
                maxRAM=$(echo $data | jq .maxRam)
                maxStorage=$(echo $data | jq .maxStorage)
                cveCount=$(echo $data | jq .cve[].id | wc -l)
                allCveCount=$(echo $cveList | jq .cve[].id | wc -l)
                userCveList=$(echo $data | jq -r .cve[].id)
        #Data expose
                #dataExpose
        #VM Data generation
                declare -A instances
                declare -A allOSes
                declare -A allVersions
                for (( i=0; i<$instancesCount; i++ ))
                do
                        for (( k=0; k<$allCveCount; k++ ))
                        do
                                if [[ "$(echo $data | jq .cve[$i].id)" == "$(echo $cveList | jq .cve[$k].id)" ]]
                                then
                                        finalPosition=$(( $(echo $RANDOM | head -c 2 | tail -c 1)%5 ))
                                        while [[ "${allIndexes[*]}" =~ "${finalPosition}" ]]
                                        do
                                                finalPosition=$(( $(echo $RANDOM | head -c 2 | tail -c 1)%5 ))
                                        done
                                        allIndexes[${#allIndexes[@]}]=${finalPosition}
                                        #echo "INDEX: $finalPosition"
                                        instances[$finalPosition,'id']=$(echo $cveList | jq -r .cve[$k].id)
                                        instances[$finalPosition,'os']=$(echo $cveList | jq -r .cve[$k].os)
                                        allOSes[$i]=${instances[$finalPosition,'os']}
                                        instances[$finalPosition,'version']=$(echo $cveList | jq -r .cve[$k].version)
                                        allVersions[$i]=${instances[$finalPosition,'version']}
                                        instances[$finalPosition,'user']=$(username)
                                        instances[$finalPosition,'pass']=$(password)
                                        break
                                fi
                        done
                        if [[ -z "${instances[$i,'id']}" ]]
                        then
                                 instances[$i,'id']="-\t\t" #$(echo $cveList | jq -r .cve[$k].id)
                                 instances[$i,'os']="TODO" #$(echo $cveList | jq -r .cve[$k].os)
                                 instances[$i,'version']="TODO" #$(echo $cveList | jq -r .cve[$k].version)
                                 instances[$i,'user']=$(username)
                                 instances[$i,'pass']=$(password)
                        fi
                done
        #Logic
                echo -e "[LinkedProcess] ${BOLD}Base analysis${NONE}"
                if (( $(isOnlyWindows "${allOSes[@]}") == "0" ))
                then
                        if (( $(isThereANeedForDifferentOS "$(echo $data | jq -r .needForDifferentOS)") == 0 ))
                        then
                                echo ""
                        else
                                if (( $(willBeEnoughCves "$cveCount" "$instancesCount") == 0 ))
                                then
                                        echo ""
                                else
                                        echo ""
                                fi
                        fi
                else
                        if (( $(isOnlyLinux "${allOSes[@]}") == 0 ))
                        then
                                echo ""
                        else
                                if (( $(willBeEnoughCves "$cveCount" "$instancesCount") == 0 ))
                                then
                                        echo -e "\t[AutomaticLink] Transition\n\t[LinkedProcess] ${BOLD}Webserver${NONE}\t($(date))"
                                        if (( $(isThereANeedFor "WEBSERVER" "webserver") == 0 ))
                                        then
                                                if (( $(isThereCveFor "WEBSERVER" "debian" "${allVersions[@]}") == 0 ))
                                                then
                                                        if (( $(moreThanOneCveFor "WEBSERVER" "debian" "${allVersions[@]}") == 0 ))
                                                        then
                                                                echo "reiks paimt random budu is user'io pateikto saraso"
                                                        else
                                                                webserverID=$(takeThatOnlyAvailableCveFromUserInput "WEBSERVER" "debian" "$cveCount" "$allCveCount")
                                                                if (( "$webserverID" == "1" )) || [ -z "$webserverID" ]
                                                                then
                                                                        echo "error"
                                                                else
                                                                        echo -e "\t\t[Stage] ${GREEN}WebserverID: $webserverID ${NONE}" >$(tty)
                                                                fi
                                                        fi
                                                fi
                                        else
                                                webserverID=$(echo "none")
                                                echo -e "\t\t[Stage] ${GREEN}WebserverID: $webserverID ${NONE}" >$(tty)
                                        fi
                                        if (( $(isThereANeedFor "WORDPRESS" "wordpress") == 0 ))
                                        then
                                                if (( $(isThereCveFor "WORDPRESS" "wordpress" "${allVersions[@]}") == 0 ))
                                                then
                                                        if (( $(moreThanOneCveFor "WORDPRESS" "wordpress" "${allVersions[@]}") == 0 ))
                                                        then
                                                                echo "reiks paimt random budu is user'io pateikto saraso"
                                                        else
                                                                wordpressID=$(takeThatOnlyAvailableCveFromUserInput "WORDPRESS" "wordpress" "$cveCount" "$allCveCount")
                                                                if (( "$wordpressID" == "1" )) || [ -z "$wordpressID" ]
                                                                then
                                                                        echo "error"
                                                                else
                                                                        echo -e "\t\t[Stage] ${GREEN}WordpressID: $wordpressID ${NONE}" >$(tty)
                                                                fi
                                                        fi
                                                else
                                                        wordpressID=$(takeRandomCveFor "WORDPRESS" "wordpress" "$allCveCount")
                                                        if (( "$wordpressID" == "1" )) || [ -z "$wordpressID" ]
                                                        then
                                                                echo "error"
                                                        else
                                                                echo -e "\t\t[Stage] ${GREEN}WordpressID: $wordpressID ${NONE}" >$(tty)
                                                        fi
                                                fi
                                        else
                                                wordpressID=$(echo "none")
                                                echo -e "\t\t[Stage] ${GREEN}WordpressID: $wordpressID ${NONE}" >$(tty)
                                        fi
                                        if (( $(isThereANeedFor "APACHE" "apache") == 0 ))
                                        then
                                                if (( $(isThereCveFor "APACHE" "apache" "${allVersions[@]}") == 0 ))
                                                then
                                                        if (( $(moreThanOneCveFor "APACHE" "apache" "${allVersions[@]}") == 0 ))
                                                        then
                                                                echo "reiks paimt random budu is user'io pateikto saraso"
                                                        else
                                                                apacheID=$(takeThatOnlyAvailableCveFromUserInput "APACHE" "apache" "$cveCount" "$allCveCount")
                                                                if (( "$apacheID" == "1" )) || [ -z "$apacheID" ]
                                                                then
                                                                        echo "error"
                                                                else
                                                                        echo -e "\t\t[Stage] ${GREEN}ApacheID: $apacheID ${NONE}" >$(tty)
                                                                fi
                                                        fi
                                                else
                                                        apacheID=$(takeRandomCveFor "APACHE" "apache" "$allCveCount")
                                                        if (( "$apacheID" == "1" )) || [ -z "$apacheID" ]
                                                        then
                                                                echo "error"
                                                        else
                                                                echo -e "\t\t[Stage] ${GREEN}ApacheID: $apacheID ${NONE}" >$(tty)
                                                        fi
                                                fi
                                        else
                                                apacheID=$(echo "none")
                                                echo -e "\t\t[Stage] ${GREEN}ApacheID: $apacheID ${NONE}" >$(tty)
                                        fi
                                        echo -e "\t[LinkedProcess] ${BOLD}Webserver end${NONE}"
                                        echo -e "\t[AutomaticLink] Transition\n\t[LinkedProcess] ${BOLD}Database start${NONE}"
                                        if (( $(isThereANeedFor "DATABASE" "database") == 0 ))
                                        then
                                                if (( $(isThereCveFor "DATABASE" "debian" "${allVersions[@]}") == 0 ))
                                                then
                                                        if (( $(moreThanOneCveFor "DAATABASE" "debian" "${allVersions[@]}") == 0 ))
                                                        then
                                                                echo "reiks paimt random budu is user'io pateikto saraso"
                                                        else
                                                                databaseID=$(takeThatOnlyAvailableCveFromUserInput "DATABASE" "debian" "$cveCount" "$allCveCount")
                                                                if (( "$databaseID" == "1" )) || [ -z "$databaseID" ]
                                                                then
                                                                        echo "error"
                                                                else
                                                                        echo -e "\t\t[Stage] ${GREEN}DatabaseID: $databaseID ${NONE}" >$(tty)
                                                                fi
                                                        fi
                                                else
                                                        databaseID=$(takeRandomCveFor "DATABASE" "debian" "$allCveCount")
                                                        if (( "$apacheID" == "1" )) || [ -z "$apacheID" ]
                                                        then
                                                                echo "error"
                                                        else
                                                                echo -e "\t\t[Stage] ${GREEN}DAtabaseID: $databaseID ${NONE}" >$(tty)
                                                        fi
                                                fi
                                        else
                                                databaseID=$(echo "none")
                                                echo -e "\t\t[Stage] ${GREEN}DatabaseID: $databaseID ${NONE}" >$(tty)
                                        fi
                                fi
                        fi #END OF isOnlyLinux
                fi #END OF isOnlyWindows



        #VM Data expose
                #for (( i=0; i<${instancesCount}; i++ ))
                #do
                #       echo -e "\n -------------------------------"
                #        echo -e "| $( expr $i + 1 ). Instance\t\t\t|"
                #        echo -e "|       CVE: ${RED}${instances[$i,'id']}${NONE}\t|"
                #        echo -e "|       OS: ${RED}${instances[$i,'os']}${NONE}\t\t|"
                #        echo -e "|       Version: ${RED}${instances[$i,'version']}${NONE}\t\t|"
                #        echo -e "|       Username: ${RED}${instances[$i,'user']}${NONE}\t\t|"
                #        echo -e "|       Password: ${RED}${instances[$i,'pass']}${NONE}   \t|"
                #        echo -e " -------------------------------"
                #done
                #echo -e "\nAll array members: ${allIndexes[@]}"
                #echo "Is only Windows? "; if (( $(isOnlyWindows "${allOSes[@]}") == 0 )); then echo "Yes"; else echo "No"; fi;
                #echo "Is only Linux? "; if (( $(isOnlyLinux "${allOSes[@]}") == 0 )); then echo "Yes"; else echo "No"; fi;
};

#checkIfJqIsAvailable
main
