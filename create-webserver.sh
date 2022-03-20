#!/bin/bash

echo -e "\n\nCREATING NEW SSH KEY PAIRS SSH\n\n"
ssh-keygen
echo -e "\n\nADDING SSH KEYS INTO THE SSH AUTHENTICATION AGENT\n\n"
eval `ssh-agent`
sudo chmod 400 .ssh/id_rsa.pub
ssh-add
ssh-add -l
echo -e "\n\nCOPY THIS KEY TO YOUR OPENNEBULA PROFILE\nYOU HAVE 60 SECONDS...\n"
cat /root/.ssh/id_rsa.pub
sleep 60

echo -e "\n\nInstalling OS updates\n\n"
sudo apt update
echo -e "\n\nInstalling git\n\n"
sudo apt-get install git -y
echo -e "\n\nInstalling OpenNebula\n\n"
git clone https://github.com/OpenNebula/one.git
sudo apt-get install gnupg2 -y
wget -q -O https://downloads.opennebula.org/repo/repo.key | sudo apt-key add -
echo "deb https://downloads.opennebula.org/repo/5.6/Ubuntu/18.04 stable opennebula" | sudo tee /etc/apt/suorces.list.d/opennebula.list
sudo apt update
echo -e "\n\nInstalling OpenNebula Tools\n\n"
sudo apt-get install opennebula-tools
echo -e "\n\nInstalling Ansible\n\n"
sudo apt-get install ansible-y
ansible --version
echo -e "\n\nCreating VMs\n\n"
CUSER=gyjo7388
CPASS="Gytis123"
CENDPOINT=https://grid5.mif.vu.lt/cloud3/RPC2

CVMREZ=$(onetemplate instantiate "debian11-5G" --name "WEBSERVER_VM" --raw TCP_PORT_FORWARDING=80 --user $CUSER --password $CPASS --endpoint $CENDPOINT)
WEBSERVERID=$(echo $CVMREZ | cut -d ' ' -f 3)
rcho -e "\n\nWEBSERVER ID: ${WEBSERVERID}"
