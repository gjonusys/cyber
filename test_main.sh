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
        #pirmas yra cveCount o antras yra instancesCount
        local minimumReq=$(echo $(( ($2 + 2 - 1) / 2 )))
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
                os=$(echo $3 | jq -r .cve[$i].os)
                if [[ "$os" = 'windows' ]] || [[ "$os" = 'linux' ]]
                then
                        allIDs[$j]=$(echo $3 | jq -r .cve[$i].id)
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
				echo -e "[LinkedProcess] ${BOLD}Base analysis${NONE}" >$(tty)
		
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
				
                if (( $(isOnlyWindows "${allOSes[@]}") == "0" ))
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
												echo "1"
										fi
                                else
                                        echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                fi
                        else
                                if (( $(willBeEnoughCves "$cveCount" "$instancesCount") == 0 ))
                                then
                                        echo "\t[AutomaticLink] Transition\n\t[Stage] Base Analysis OK\n\t[AutomaticLink] Transition\n[LinkedProcess] ${BOLD}Base Analysis END${NONE}" >$(tty)
										echo "0"
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
														echo "1"
												fi
                                        else
                                                echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                        fi
                                fi
                        fi
                else
                        if (( $(isOnlyLinux "${allOSes[@]}") == 0 ))
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
														echo "1"
												fi
                                        else
                                                echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                        fi
                                else
                                        if (( $(willBeEnoughCves "$cveCount" "$instancesCount") == 0 ))
                                        then
                                                echo -e "\t[AutomaticLink] Transition\n\t[Stage] Base Analysis OK\n[LinkedProcess] ${BOLD}Base analysis END${NONE}" >$(tty)
												echo "0"
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
																echo "1"
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
										echo "0"
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
														echo "1"
												fi
                                        else
                                                echo -e "\t\t[Stage] User will input CVEs by himself\n\tEXITING..." >$(tty) && exit 1
                                        fi
                                fi
						fi
                fi
};

function main () {
        echo -e "[Process] Main process \t($(date))"
        echo -e "[Stage] The user \"$USER\" has started the process"
        echo -e "[LinkedProcess] Transition"
        requirementsCheck
		baseAnalysis
       


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
