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
};

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
                echo -e "$1\t[LogicLink] Yes" >$(tty)
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
        local cveList=$1
        for (( i=1; i<=$(( $(echo $cveList | tr -cd ' ' | wc -c) + 1 )); i++ ))
        do
                cve=$(echo $cveList | cut -d ' ' -f $i)
                answer=$(curl -s "https://services.nvd.nist.gov/rest/json/cve/1.0/$cve" | jq -r .result.CVE_Items[0].configurations.nodes[0].cpe_match[0].cpe23Uri)
                answer1=$(echo $answer | cut -d ':' -f 4)
                answer2=$(echo $answer | cut -d ':' -f 5)
                if [[ "$answer1" = 'linux' ]] || [[ "$answer2" = 'linux' ]]
                then
                        echo -e "\t[LogicLink] No" >$(tty)
                        echo "1" && return 1
                        exit 1
                fi
        done

        echo -e "\t[LogicLink] Yes" >$(tty)
        echo "0" && return 0
};

function isOnlyLinux () {
        echo -e "\t[Decision] Is only Linux?" >&$(tty)
        local cveList=$1
        for (( i=1; i<=$(( $(echo $cveList | tr -cd ' ' | wc -c) + 1 )); i++ ))
        do
                cve=$(echo $cveList | cut -d ' ' -f $i)
                answer=$(curl -s "https://services.nvd.nist.gov/rest/json/cve/1.0/$cve" | jq -r .result.CVE_Items[0].configurations.nodes[0].cpe_match[0].cpe23Uri)
                answer1=$(echo $answer | cut -d ':' -f 4)
                answer2=$(echo $answer | cut -d ':' -f 5)
                if [[ "$answer1" = 'microsoft' ]] || [[ "$answer2" = 'microsoft' ]]
                then
                        echo -e "\t[LogicLink] No" >$(tty)
                        echo "1" && return 1
                        exit 1
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

function willUserInputByHimself () {
        read -p "$(echo -e "\t")[UserInput] y/n? " userInput >$(tty)
        if [[ "$userInput" = 'y' ]]
        then
                echo -e "\t[LogicLink] Yes" >$(tty)
                echo "1" && return 1
        elif [[ "$userInput" = 'n' ]]
        then
                echo -e "\t[LogicLink] No" >$(tty)
                echo "0" && return 0
        else
                echo -e "\t[LogicLink] No" >$(tty)
                echo "2" && return 2
        fi
};

function howManyCVEsNeeded () {
        echo -e "\t\t[Action] Calculation of how many CVEs are needed" >$(tty)
        local result=$(echo $(( $1 * 100 / $2 )))
        local minimumReq=$(echo $(( ($2 + 2 - 1) / 2 ))) #minimum quantity of CVEs per all instances
        local needed=$(echo $(( $minimumReq - $1 )))
        echo -e "\t\t[Result] The cyber range needs $needed more CVE(-s)" >$(tty)
        if [ -z "$needed" ]
        then
                echo -e "ERROR" && return 1
        else
                echo -e "$needed" && return 0
        fi
};

function chooseCVEs () {
        echo -e "\t\t[Action] Choosing random CVEs" >$(tty)
        j=0
        result=""
        declare -A allIDs
        for (( i=0; i<$1; i++))
        do
                cve=$(echo $3 | jq -r .cve[$i].id)
                answer=$(curl -s "https://services.nvd.nist.gov/rest/json/cve/1.0/$cve" | jq -r .result.CVE_Items[0].configurations.nodes[0].cpe_match[0].cpe23Uri)
                answer1=$(echo $answer | cut -d ':' -f 4)
                answer2=$(echo $answer | cut -d ':' -f 5)
                if [[ "$answer1" = 'microsoft' ]] || [[ "$answer2" = 'microsoft' ]] || [[ "$answer1" = 'linux' ]] || [[ "$answer2" = 'linux' ]]
                then
                        allIDs[$j]=$cve
                        ((j++))
                fi
        done

        if [[ "$4" != 'BLANK' ]]
        then
                position=$(( $(echo $RANDOM | head -c 2)%j ))
                result="${result} ${allIDs[$position]}"
                echo -e "\t\t[Result] Chosen CVE(-s): $result" >$(tty)
                if [ -z "$result" ]
                then
                        echo "1" && return 1
                else
                        echo -e "$result" && return 0
                fi
        fi

        for (( k=0; k<$2; k++ ))
        do
                position=$(( $(echo $RANDOM | head -c 2)%$j ))
                result="${result} ${allIDs[$position]}"
        done
        echo -e "\t\t[Result] Chosen CVE(-s): $result" >$(tty)
        if [ -z "$result" ]
        then
                echo "1" && return 1
        else
                echo -e "$result" && return 0
        fi

};

function assignCVEs () {
        echo -e "\t\t[Action] Assign chosen CVEs" >$(tty)
        cveList=$3
        cveListOld=$cveList

        for (( i=1; i<=$1; i++ ))
        do
                id=$(echo $2 | cut -d " " -f$i)
                cveList="${cveList} ${id}"
        done

        cveList=$(echo "${cveList}" | tr ' ' '\n')
        if [[ "$cveList" != "$cveListOld" ]]
        then
                echo -e "\t\t[Result] New CVEs are assigned" >$(tty)
                echo "$cveList" && return 0
        else
                echo "1" && return 1
        fi
};

function countAndGetLinuxCVEs () {
        echo -e "\n\t[Action] Calculation of how many CVEs for Linux OS are included" >$(tty)
        j=0
        result=""
        allCveCount=$(cat ./cve_list.json | jq -r .cve[].id | wc -l)
        declare -A linuxCVEs

        for (( b=1; b<=$1; b++ ))
        do
                cveFromUsersInput=$(echo $2 | tr ' ' '\n' | head -n $b | tail -n 1)
                answer=$(curl -s "https://services.nvd.nist.gov/rest/json/cve/1.0/$cveFromUsersInput" | jq -r .result.CVE_Items[0].configurations.nodes[0].cpe_match[0].cpe23Uri)
                answer1=$(echo $answer | cut -d ':' -f 4)
                answer2=$(echo $answer | cut -d ':' -f 5)
                #echo -e "ANSWER: $cveFromUserInput - $answer1 - $answer2" >$(tty)
                if [[ "$answer1" = 'linux' ]] || [[ "$answer2" = 'linux' ]]
                then
                        result="${result} ${cveFromUsersInput}"
                        ((j++))
                fi
        done
        echo -e "\t[Result] Number of CVEs for Linux OS: $j" >$(tty)
        echo -e "\t[Action] Getting CVEs that are only for Linux OS" >$(tty)
        result=${result:1}
        echo -e "\t[Result] List of Linux CVEs: $result" >$(tty)
        result="${j},${result}"

        if [ -z "$result" ]
        then
                echo "-1" && return 1
        else
                echo "$result" && return 0
        fi
};

function getLinuxCvesForMainComponentsAndNot () {
        echo -e "\t[Action] Distributing Linux CVEs for three Main Components" >$(tty)
        linuxCount=$(echo $1 | cut -d ',' -f 1)
        linuxCves=$(echo $1 | cut -d ',' -f 2)
        proportion=$(cat ./data.json | jq .proportionLinuxCvesForMainComponents)

        require=$(echo $(( ($linuxCount + 2 - 1) * $proportion / 100 )))
        echo -e "\t[Result] Main components will get $require CVE(-s)" >$(tty)
        echo -e "\t[Action] Assign $require CVE(-s) for Main Components" >$(tty)
        result=$(getRandomCvesFromInput "$require" "$linuxCount" "$linuxCves" "Main Components")
        result="$require,$result"
        echo -e "\t\t[AutomaticLink] Transition\n\t[Result] CVEs have been assigned: $result" >$(tty)
        echo -e "$result" && return 0
};

function getRandomNumberWithLimit () {
        echo -e "\t\t[Action] Get a Random Number" >$(tty)
        echo -e "\t\t[Decision] Is an inputed number valid?" >$(tty)
        inputedNumber=$1
        if [[ "$inputedNumber" -gt 0 ]]
        then
                echo -e "\t\t[LogicLink] Yes" >$(tty)
        else
                echo -e "\t\t[LogicLink] No" >$(tty)
                echo "-1" && return 1 && exit 1
        fi
        randomNumber=$(( $(echo $RANDOM | head -n 2)%$inputedNumber ))
        leftNumber=$(( $inputedNumber - $randomNumber ))
        result="${randomNumber},${leftNumber}"
        echo -e "\t\t[Decision] Is the Random Number valid?" >$(tty)
        if [[ ! -z "$result" ]]
        then
                echo -e "\t\t[LogicLink] Yes" >$(tty)
                echo "$result" && return 0
        else
                echo -e "\t\t[LogicLink] No" >$(tty)
                echo "-1" && return 1
        fi
};

function getRandomCvesFromInput () {
        echo -e "\t\t[Action] Take $1 CVE(-s)" >$(tty)
        local requiredCount=$1
        local fullCount=$2
        local cveList=$(echo $3)
        local instanceName=$4
        local newCveList=""
        local leftLinuxCves=""
        declare -A linuxCves

        echo -e "\t\t[Decision] Are parameters valid?" >$(tty)
        if [[ "$requiredCount" -le "$fullCount" ]]
        then
                echo -e "\t\t[LogicLink] Yes" >$(tty)
        else
                echo -e "\t\t[LogicLink] No" >$(tty)
                echo "1" && return 1 && exit 1
        fi

        for (( i=1; i<=$fullCount; i++ ))
        do
                j=$(( $i + 1 ))
                linuxCves[$i]=$(echo $cveList | cut -d " " -f $i )
                #echo -e "LinuxCVEsFromLOOP: ${linuxCves[$i]}" >$(tty)
        done

        for (( i=0; i<$requiredCount; i++ ))
        do
                randomNumber=$(( $(echo $RANDOM | head -n 3)%$fullCount ))
                if [[ "$randomNumber" -lt 1 ]] || [[ "$randomNumber" -gt "$fullCount" ]]
                then
                        randomNumber=$fullCount
                fi
                #echo "RANDOM NUMBER: $randomNumber" >$(tty)
                randomCve=${linuxCves[$randomNumber]}
                #echo "RANDOM CVE: $randomCve" >$(tty)
                for (( j=$randomNumber; j<$fullCount; j++ ))
                do
                        linuxCves[$j]=${linuxCves[$(( $j + 1 ))]}
                done
                newCveList="${newCveList} ${randomCve}"
                ((fullCount--))
        done

        for (( i=1; i<=$fullCount; i++ ))
        do
                leftLinuxCves="${leftLinuxCves} ${linuxCves[$i]}"
        done

        newCveList=$(echo "${newCveList:1}") && leftLinuxCves=$(echo "${leftLinuxCves:1}")
        echo -e "\t\t[Result] ${GREEN}$instanceName CVE(-s): $newCveList ${NONE}" >$(tty)
        result="$newCveList,$leftLinuxCves"

        echo "$result" && return 0
};

function checkIsThereLinuxCves () {
        echo -e "\t\t\t\t[Decision] Has component got Linux CVEs?" >$(tty)
        if [[ "$1" -gt 0 ]]
        then
                echo -e "\t\t\t\t[LogicLink] Yes" >$(tty)
                echo "0" && return 0
        else
                echo -e "\t\t\t\t[LogicLink] No" >$(tty)
                echo "1" && return 1
        fi
};

function assignLinuxCves () {
        echo -e "\t\t\t[LinkedProcess] Linux CVEs for $3 START" >$(tty)
        if (( $(checkIsThereLinuxCves "$1") == 0 ))
        then
                echo -e "\t\t\t\t[Action] Assign $1 CVE(-s)" >$(tty)
                result="$2"
                echo -e "\t\t\t\t[Result] Completed" >$(tty)
        else
                echo -e "\t\t\t\t[Stage] There are not any CVEs for $3" >$(tty)
                result=""
        fi
        echo -e "\t\t\t\t[AutomaticLink] Transition\n\t\t\t[LinkedProcess] Linux CVEs for $3 END" >$(tty)
        echo "$result" && return 0
};

function isThereOtherCves () {
        echo -e "\t\t\t\t[Decision] Has component got software CVEs for $4?" >$(tty)
        cveList=$(echo $2 | tr '\n' ' ')
        cveListCount=$1

        for (( i=1; i<=$cveListCount; i++ ))
        do
                cve=$(echo $cveList | cut -d ' ' -f $i)
                answer=$(curl -s "https://services.nvd.nist.gov/rest/json/cve/1.0/$cve" | jq -r .result.CVE_Items[0].configurations.nodes[0].cpe_match[0].cpe23Uri)
                answer1=$(echo $answer | cut -d ':' -f 4)
                answer2=$(echo $answer | cut -d ':' -f 5)
                for (( j=1; j<=$(( $(echo $3 | tr -cd , | wc -c) + 1 )); j++ ))
                do
                        local var=$(echo $3 | cut -d ',' -f $j)
                        if [[ "$answer1" = "$var" ]] || [[ "$answer2" = "$var" ]]
                        then
                                echo -e "\t\t\t\t[LogicLink] Yes" >$(tty) && echo "0" && return 0 && exit 0
                        fi
                done
        done
        echo -e "\t\t\t\t[LogicLink] No" >$(tty) && echo "1" && return 1
};

function assignOtherCves () {
        echo -e "\t\t\t[LinkedProcess] Software CVEs for $5 START\t($4)" >$(tty)
        result=$1
        if [ -z "$result" ]
        then
                varempty=1
        else
                varempty=0
        fi
        if (( $(isThereOtherCves "$2" "$3" "$4" "$5") == 0 ))
        then
                echo -e "\t\t\t\t[Action] Assign all $5 CVEs" >$(tty)
                for (( i=1; i<=$2; i++ ))
                do
                        cve=$(echo $3 | cut -d ' ' -f $i)
                        answer=$(curl -s "https://services.nvd.nist.gov/rest/json/cve/1.0/$cve" | jq -r .result.CVE_Items[0].configurations.nodes[0].cpe_match[0].cpe23Uri)
                        answer1=$(echo $answer | cut -d ':' -f 4)
                        answer2=$(echo $answer | cut -d ':' -f 4)
                        for (( j=1; j<=$(( $(echo $4 | tr -cd , | wc -c) + 1 )); j++ ))
                        do
                                local var=$(echo $4 | cut -d ',' -f $j)
                                if [[ "$answer1" = "$var" ]] || [[ "$answer2" = "$var" ]]
                                then
                                        result="${result} ${cve}"
                                fi
                        done
                done
                if [[ "$varempty" -eq 1 ]]
                then
                        result=$(echo ${result:1})
                fi
                echo -e "\t\t\t\t[Result] ${GREEN}Updated $5 CVEs: $result${NONE}\n\t\t\t\t[AutomaticLink] Transition\n\t\t\t[LinkedProcess] Software CVEs for $5 END" >$(tty)
                echo "$result" && return 0
        else
                echo -e "\t\t\t\t[Stage] There are not any software CVEs for $5\n\t\t\t\t[AutomaticLink] Transition\n\t\t\t[LinkedProcess] Software CVEs for $5 END" >$(tty)
                echo "$result" && return 1
        fi
};

function completeOtherCves () {
        echo -e "\t[LinkedProcess] ${BOLD}Distribution of CVEs for other VMs START${NONE} \t($(date))" >$(tty)
        echo -e "\t[AutomaticLink] Transition" >$(tty)
        echo -e "\t\t[Action] Find not used CVEs (except dedicated for Linux OS)" >$(tty)
        excludes="linux,apache,nginx,lighttpd,caddy,mysql,postgresql,openvswitch"
        otherIds=""
        cveListCount=$1
        cveList=$2
        for (( i=1; i<=$cveListCount; i++ ))
        do
                foo=0
                cve=$(echo "$cveList" | tr '\n' ' ' | cut -d ' ' -f $i)
                answer=$(curl -s "https://services.nvd.nist.gov/rest/json/cve/1.0/$cve" | jq -r .result.CVE_Items[0].configurations.nodes[0].cpe_match[0].cpe23Uri)
                answer1=$(echo $answer | cut -d ':' -f 4)
                answer2=$(echo $answer | cut -d ':' -f 5)
                for (( j=1; j<=$(( $(echo $excludes | tr -cd , | wc -c) + 1 )); j++ ))
                do
                        var=$(echo $excludes | cut -d ',' -f $j)
                        if [[ "$answer1" = "$var" ]] || [[ "$answer2" = "$var" ]]
                        then
                                ((foo++))
                        fi
                done
                if [[ "$foo" -eq 0 ]]
                then
                        otherIds="${otherIds} ${cve}"
                fi
        done

        otherIds=$(echo "${otherIds:1}")
        echo -e "\t\t[Result] Found CVE(-s): $otherIds" >$(tty)
        echo -e "\t\t[Action] Find not used Linux CVE(-s)" >$(tty)
        otherIdsLinux=$(echo $linuxCvesDistributed | cut -d ',' -f 3)
        echo -e "\t\t[Result] Found CVE(-s): $otherIdsLinux" >$(tty)
        echo -e "\t\t[Action] Merge all CVEs that were unused" >$(tty)
        otherIds="${otherIds} ${otherIdsLinux}"
        echo "$otherIds"
        echo -e "\t\t[Result] Merged CVEs: $otherIds" >$(tty)
        echo -e "\t\t[AutomaticLink] Transition" >$(tty)
        echo -e "\t[LinkedProcess] ${BOLD}Distribution of CVEs for other VMs END${NONE}" >$(tty)
}

function username () {
        echo "admin"
};

function password () {
        pass=$(cat ./passwords.txt | head -n $(echo $RANDOM | head -c 2) | tail -n 1)
        echo $pass
};

function requirementsCheck () {
                echo -e "[LinkedProcess] ${BOLD}Requirements check START${NONE}" >$(tty)
                if (( $(areFilesAvailable) == "0" ))
                then
                        if (( $(isJqInstalled "") == "0" ))
                        then
                                echo -e "\t[AutomaticLink] Transition\n\t[Stage] Requirements are appropriate\n[LinkedProcess] ${BOLD}Requirements check END${NONE}" >$(tty)
                        else
                                if (( $(wantToInstall) == "0" ))
                                then
                                        if (( $(installJq) == "0" ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n\t[Stage] Requirements are appropriate\n[LinkedProcess] ${BOLD}Requirements check END${NONE}" >$(tty)
                                        else
                                                echo -e "${RED}Install JQ manually and restart the program.${NONE}" >$(tty) && exit 1
                                        fi
                                else
                                        echo -e "${RED}Install JQ manually and restart the program.${NONE}" >$(tty) && exit 1
                                fi
                        fi
                else
                        exit 1
                fi
                echo -e "[AutomaticLink] Transition" >$(tty)
};

function baseAnalysis () {
        echo -e "[LinkedProcess] ${BOLD}Base Analysis START${NONE} \t ($(date))" >$(tty)

                #Data gathering
                data=$(cat ./data.json)
                cveList=$(cat ./cve_list.json)
                instancesCount=$(echo $data | jq .instancesCount)
                cveCount=$(echo $data | jq .cve[].id | wc -l)
                allCveCount=$(echo $cveList | jq .cve[].id | wc -l)
                userCveList=$(echo $data | jq -r .cve[].id | tr '\n' ' ')

                if (( $(isOnlyWindows "$userCveList") == "0" ))
                then
                        if (( $(isThereANeedForDifferentOS "$(echo $data | jq -r .needForDifferentOS)") == 0 ))
                        then
                                echo -e "\t[Decision] There are inputed CVEs for only Microsoft Windows OS. Will you input more CVEs by yourself?" >$(tty)
                                if (( $(willUserInputByHimself) == "0"  ))
                                then
                                        echo -e "\t[AutomaticLink] Transition\n\t[LinkedProcess] ${BOLD}CVEs auto-generation START${NONE}\t($(date))" >$(tty)
                                        numberOfNeededCVEs=1
                                        echo -e "\t\t[Action] Calculation of how many CVEs are needed\n\t\t[Result] The cyber range needs ${numberOfNeededCVEs} CVE(-s) for other OS" >$(tty)
                                        detectedOS="windows"
                                        echo -e "\t\t[Action] Detection of a dominating OS\n\t\t[Result] Dominating OS is Microsoft Windows" >$(tty)
                                        chosenCVEs=$(chooseCVEs "$allCveCount" "$numberOfNeededCVEs" "$cveList" "$detectedOS")
                                        if [ -z "$chosenCVEs" ] || [[ "$chosenCVEs" = "1" ]]
                                        then
                                                echo -e "\t\t[Alert] ${RED}ERROR: Choosing random CVEs failed. Exiting...${NONE}" >$(tty) && exit 1
                                        else
                                                userCveList=$(assignCVEs "$numberOfNeededCVEs" "$chosenCVEs" "$userCveList")
                                                echo -e "\t\t[AutomaticLink] Transition\n\t\t[Stage] CVEs auto-generation went well\n\t[LinkedProcess] ${BOLD}CVEs auto-generation END${NONE}\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty)
                                                echo "$userCveList"
                                        fi
                                else
                                        echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                fi
                        else
                                if (( $(willBeEnoughCves "$cveCount" "$instancesCount") == 0 ))
                                then
                                        echo "\t[AutomaticLink] Transition\n\t[Stage] Base Analysis OK\n[LinkedProcess] ${BOLD}Base analysis END${NONE}\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty)
                                        echo "$userCveList"
                                else
                                        echo -e "\t[Decision] There are not enough CVEs. Will you input them by yourself?" >$(tty)
                                        if (( $(willUserInputByHimself) == "0" ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n\t[LinkedProcess] ${BOLD}CVEs auto-generation START${NONE}\t($(date))" >$(tty)
                                                numberOfNeededCVEs=$(howManyCVEsNeeded "$cveCount" "$instancesCount")
                                                chosenCVEs=$(chooseCVEs "$allCveCount" "$numberOfNeededCVEs" "$cveList" "BLANK")
                                                if [ -z "$chosenCVEs" ] || [[ "$chosenCVEs" = "1" ]]
                                                then
                                                        echo -e "\t\t[Alert] ERROR: Choosing random CVEs failed. Exiting...}" >$(tty) && exit 1
                                                else
                                                        userCveList=$(assignCVEs "$numberOfNeededCVEs" "$chosenCVEs" "$userCveList")
                                                        echo -e "\t\t[AutomaticLink] Transition\n\t\t[Stage] CVEs auto-generation OK\n\t[LinkedProcess] ${BOLD}CVEs auto-generation END${NONE}\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty)
                                                        echo "$userCveList"
                                                fi
                                        else
                                                echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                        fi
                                fi
                        fi
                else
                        if (( $(isOnlyLinux "$userCveList") == 0 ))
                        then
                                if (( $(isThereANeedForDifferentOS "$(echo $data | jq -r .needForDifferentOS)") == 0 ))
                                then
                                        echo -e "\t[Decision] There are inputed CVEs for only Linux OS. Will you input more CVEs by yourself?" >$(tty)
                                        if (( $(willUserInputByHimself) == 0 ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n\t[LinkedProcess] ${BOLD}CVEs auto-generation start${NONE}\t($(date))" >$(tty)
                                                numberOfNeededCVEs=1
                                                echo -e "\t\t[Action] Calculation of how many CVEs are needed\n\t\t[Result] The cyber range needs ${numberOfNeededCVEs} CVE(-s) for other OS" >$(tty)
                                                detectedOS="linux"
                                                echo -e "\t\t[Action] Detection of a dominating OS\n\t\t[Result] Dominating OS is Linux" >$(tty)
                                                chosenCVEs=$(chooseCVEs "$allCveCount" "$numberOfNeededCVEs" "$cveList" "$detectedOS")
                                                if [ -z "$chosenCVEs" ] || [[ "$chosenCVEs" = "1" ]]
                                                then
                                                        echo -e "\t\t[Alert] ${RED}ERROR: Choosing random CVEs failed. Exiting...${NONE}" >$(tty) && exit 1
                                                else
                                                        userCveList=$(assignCVEs "$numberOfNeededCVEs" "$chosenCVEs" "$userCveList")
                                                        echo -e "\t\t[AutomaticLink] Transition\n\t\t[Stage] CVEs auto-generation went well\n\t[LinkedProcess] ${BOLD}CVEs auto-generation END${NONE}\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty)
                                                        echo "$userCveList"
                                                fi
                                        else
                                                echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                        fi
                                else
                                        if (( $(willBeEnoughCves "$cveCount" "$instancesCount") == 0 ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n\t[Stage] Base Analysis OK\n[LinkedProcess] ${BOLD}Base analysis END${NONE}" >$(tty)
                                                echo "$userCveList"
                                        else
                                                echo -e "\t[Decision] There are not enough CVEs. Will you input them by yourself?" >$(tty)
                                                if (( $(willUserInputByHimself) == "0" ))
                                                then
                                                        echo -e "\t[AutomaticLink] Transition\n\t[LinkedProcess] ${BOLD}CVEs auto-generation START${NONE}\t($(date))" >$(tty)
                                                        numberOfNeededCVEs=$(howManyCVEsNeeded "$cveCount" "$instancesCount")
                                                        chosenCVEs=$(chooseCVEs "$allCveCount" "$numberOfNeededCVEs" "$cveList" "BLANK")
                                                        if [ -z "$chosenCVEs" ] || [[ "$chosenCVEs" = "1" ]]
                                                        then
                                                                echo -e "\t\t[Alert] ERROR: Choosing random CVEs failed. Exiting..." >$(tty) && exit 1
                                                        else
                                                                userCveList=$(assignCVEs "$numberOfNeededCVEs" "$chosenCVEs" "$userCveList")
                                                                echo -e "\t\t[AutomaticLink] Transition\n\t\t[Stage] CVEs auto-generation OK\n\t[LinkedProcess] ${BOLD}CVEs auto-generation END${NONE}\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty)
                                                                echo "$userCveList"
                                                        fi
                                                else
                                                        echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                                fi
                                        fi
                                fi
                        else
                                if (( $(willBeEnoughCves "$cveCount" "$instancesCount") == 0 ))
                                then
                                        echo -e "\t[AutomaticLink] Transition\n\t[Stage] Base Analysis OK\n[LinkedProcess] ${BOLD}Base analysis END${NONE}" >$(tty)
                                        echo "$userCveList"
                                else
                                        echo -e "\t[Decision] There are not enough CVEs. Will you input them by yourself?" >$(tty)
                                        if (( $(willUserInputByHimself) == "0" ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n\t[LinkedProcess] ${BOLD}CVEs auto-generation START${NONE}\t($(date))" >$(tty)
                                                numberOfNeededCVEs=$(howManyCVEsNeeded "$cveCount" "$instancesCount")
                                                chosenCVEs=$(chooseCVEs "$allCveCount" "$numberOfNeededCVEs" "$cveList" "BLANK")
                                                if [ -z "$chosenCVEs" ] || [[ "$chosenCVEs" = "1" ]]
                                                then
                                                        echo -e "\t\t[Alert] ERROR: Choosing random CVEs failed. Exiting..." >$(tty) && exit 1
                                                else
                                                        userCveList=$(assignCVEs "$numberOfNeededCVEs" "$chosenCVEs" "$userCveList")
                                                        echo -e "\t\t[AutomaticLink] Transition\n\t\t[Stage] CVEs auto-generation OK\n\t[LinkedProcess] ${BOLD}CVEs auto-generation END${NONE}\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty)
                                                        echo "$userCveList"
                                                fi
                                        else
                                                echo -e "\t[Stage] User will input CVEs by himself\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty) && exit 1
                                        fi
                                fi
                                                fi
                fi
};

function advancedAnalysis () {
        echo -e "[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Advanced Analysis START${NONE} \t($(date))" >$(tty)
        echo -e "\t[Action] Gathering list of CVEs that was inputed by the user:" >$(tty)
        cveList=$(echo $1 | tr ' ' '\n')
        echo -e "\t[Result] List of CVEs: $cveList" | tr '\n' ' '
        cveListCount=$(echo $cveList | tr ' ' '\n' | wc -l)
        local linuxCveCountAndList=$(countAndGetLinuxCVEs "$cveListCount" "$cveList")
        linuxCvesDistributed=$(getLinuxCvesForMainComponentsAndNot "$linuxCveCountAndList")

        linuxCveCount=$(echo $linuxCvesDistributed | cut -d',' -f1)
        linuxCveList=$(echo $linuxCvesDistributed | cut -d',' -f2)

        echo -e "\t[LinkedProcess] ${BOLD}Web Server Linux CVE(-s) Distribution START${NONE}"
        webserverLinuxCvesCount=$(echo $(getRandomNumberWithLimit "$linuxCveCount") | cut -d',' -f1)
        #webserverLinuxCvesCount=2
        result=$(getRandomCvesFromInput "$webserverLinuxCvesCount" "$linuxCveCount" "$linuxCveList" "Web Server")
        webserverLinuxCves=$(echo $result | cut -d "," -f 1)
        #echo "RESULT: $result"
        echo -e "\t[LinkedProcess] ${BOLD}Web server Linux CVE(-s) Distribution END${NONE}" >$(tty)

        linuxCveCount=$(( ${linuxCveCount} - ${webserverLinuxCvesCount} ))
        linuxCveList=$(echo $result | cut -d "," -f 2)
        echo -e "\t[AutomaticLink] Transition" >$(tty)

        echo -e "\t[LinkedProcess] ${BOLD}Database Linux CVE(-s) Distribution START${NONE}" >$(tty)
        databaseLinuxCvesCount=$(echo $(getRandomNumberWithLimit "$linuxCveCount") | cut -d ',' -f1 )
        #databaseLinuxCvesCount=1
        result=$(getRandomCvesFromInput "$databaseLinuxCvesCount" "$linuxCveCount" "$linuxCveList" "Database")
        databaseLinuxCves=$(echo $result | cut -d "," -f 1)
        #echo "RESULT: $result"
        echo -e "\t[LinkedProcess] ${BOLD}Database Linux CVE(-s) Distribution END${NONE}" >$(tty)


        echo -e "\t[AutomaticLink] Transition" >$(tty)
        linuxCveCount=$(( ${linuxCveCount} - ${databaseLinuxCvesCount} ))
        linuxCveList=$(echo $result | cut -d "," -f 2)

        echo -e "\t[LinkedProcess] ${BOLD}Networking Linux CVE(-s) Distribution START${NONE}" >$(tty)
        result=$(getRandomCvesFromInput "$linuxCveCount" "$linuxCveCount" "$linuxCveList" "Networking")
        networkingLinuxCves=$(echo $result | cut -d "," -f 1)
        #echo "RESULT: $result"
        echo -e "\t[LinkedProcess] ${BOLD}Networking Linux CVE(-s) Distribution END${NONE}"

        echo -e "\t[AutomaticLink] Transition"
        echo -e "\t[LinkedProcess] ${BOLD}Advanced Analysis of three main components START${NONE} \t($(date))"
        echo -e "\t[AutomaticLink] Transition"
        echo -e "\t\t[LinkedProcess] ${BOLD}Advanced Analysis of the Web Server START${NONE} \t($(date))"
        echo -e "\t\t[AutomaticLink] Transition" >$(tty)
        webserverCves=$(assignLinuxCves "$webserverLinuxCvesCount" "$webserverLinuxCves" "Web Server")
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)
        webserverCves=$(assignOtherCves "$webserverCves" "$cveListCount" "$cveList" "apache,nginx,lighttpd,caddy" "Web Server")
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)
        webserverCves=$(assignOtherCves "$webserverCves" "$cveListCount" "$cveList" "wordpress,prestashop" "Web Server")
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)
        echo -e "\t\t\t[Stage] ${GREEN}All Web Server CVEs: $webserverCves${NONE}" >$(tty)
        echo -e "\t\t[LinkedProcess] ${BOLD}Advanced Analysis of the Web Server END${NONE}" >$(tty)
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)

        echo -e "\t\t[LinkedProcess] ${BOLD}Advanced Analysis of the Database START${NONE} \t($(date))"
        echo -e "\t\t[AutomaticLink] Transition" >$(tty)
        databaseCves=$(assignLinuxCves "$databaseLinuxCvesCount" "$databaseLinuxCves" "Database")
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)
        databaseCves=$(assignOtherCves "$databaseCves" "$cveListCount" "$cveList" "mysql,postgresql" "Database")
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)
        echo -e "\t\t\t[Stage] ${GREEN}All Database CVEs: $databaseCves${NONE}" >$(tty)
        echo -e "\t\t[LinkedProcess] ${BOLD}Advanced Analysis of the Database END${NONE}" >$(tty)
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)

        echo -e "\t\t[LinkedProcess] ${BOLD}Advanced Analysis of the Networking START${NONE} \t($(date))"
        echo -e "\t\t[AutomaticLink] Transition" >$(tty)
        networkingCves=$(assignLinuxCves "$linuxCveCount" "$networkingLinuxCves" "Networking")
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)
        networkingCves=$(assignOtherCves "$networkingCves" "$cveListCount" "$cveList" "openvswitch" "Networking")
        echo -e "\t\t\t[AutomaticLink] Transition" >$(tty)
        echo -e "\t\t\t[Stage] ${GREEN}All Networking CVEs: $networkingCves${NONE}" >$(tty)
        echo -e "\t\t[LinkedProcess] ${BOLD}Advanced Analysis of the Networking END${NONE}" >$(tty)
        echo -e "\t\t[AutomaticLink] Transition" >$(tty)
        echo -e "\t[LinkedProcess] ${BOLD}Advanced Analysis of three main components END${NONE}" >$(tty)
        echo -e "\t[AutomaticLink] Transition" >$(tty)
        otherIds=$(completeOtherCves "$cveListCount" "$cveList")
        echo -e "\t[Action] Merge all CVEs of the Cyber Range" >$(tty)
        result="${webserverCves},${databaseCves},${networkingCves},${otherIds}"
        echo -e "\t[Result] ${GREEN}${BOLD}All CVEs: $result${NONE}" >$(tty)

};

function main () {
        echo -e "[Process] Main process \t($(date))"
        echo -e "[Stage] The user \"$USER\" has started the process"
        echo -e "[LinkedProcess] Transition"
        requirementsCheck
        userCveList=$(baseAnalysis)
        if [ -z "$userCveList" ]
        then
                echo -e "${RED}[Alert] Exiting...${NONE}"
        else
                advancedAnalysis "$userCveList"
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
