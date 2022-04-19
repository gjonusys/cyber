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
                echo -e "[Stage] ${BOLD}Requirements check${NONE}"
                if (( $(areFilesAvailable) == "0" ))
                then
                        if (( $(isJqInstalled "") == "0" ))
                        then
                                echo -e "\t[AutomaticLink] Transition\n[Stage] ${BOLD}Requirements are appropriate${NONE}"
                        else
                                if (( $(wantToInstall) == "0" ))
                                then
                                        if (( $(installJq) == "0" ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n[Stage] ${BOLD}Requirements are appropriate${NONE}"
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
        #Data expose
                #dataExpose
        #VM Data generation
                declare -A instances
                declare -A allOSes
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
                echo -e "[Stage] ${BOLD}Base analysis${NONE}"
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
                                        echo ""
                                else
                                        echo ""
                                fi
                        fi
                fi

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
