#!/bin/bash

# Ansible Install & Configuration
# Author: Michael Jiang
# Version 01.29.2018
#


############################### Variable Definition

# Variables - Ansible folders
dir_git="$HOME/git"
dir_ansible="$dir_git/Ansible"
dir_inventory="$dir_ansible/inventory"
dir_groupvars="$dir_inventory/group_vars"
dir_playbooks="$dir_ansible/playbooks"
dir_roles="$dir_ansible/roles"

# Variables - Ansible inventory
file_inv_ansible="$dir_inventory/inventory.yml"
file_inv_groupvars_all="$dir_groupvars/all.yml"
AS_eB=""
AS_CS=""
IPs_eB=""
IPs_CS=""

# Variables - Ansible playbooks & roles
file_pb="playbooks/eb.yml"
url_zip_playbook="https://s3.ca-central-1.amazonaws.com/suncor-adlp/Ansible/playbooks/playbooks.zip"
url_zip_roles="https://s3.ca-central-1.amazonaws.com/suncor-adlp/Ansible/roles/roles.zip"

# Variables - Configuration
file_config_ansible="$dir_ansible/ansible.cfg"
ansible_user=""
ansible_pass=""

# General Variables
ipPattern="^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$"
awsRegion="ca-central-1"
dir_log="$HOME/var/log"
playbookLog="$dir_log/ansibleInstall_runPlaybook.log"

############################### End Variable Definition
#
############################### Functions Definition

echoProcessStatus(){
  local lineLen=60
  local statusTxt=$1
  local functionTxt=$2
  local numStarsStart=$(($(($lineLen-${#statusTxt}-${#functionTxt}-4))/2))
  local numStarsEnd=$(($numStarsStart+$(($(($lineLen-${#statusTxt}-${#functionTxt}-4))%2))))
  for i in `seq 1 $lineLen`; do
    printf "*"
  done
  printf "\n"
  for i in `seq 1 $numStarsStart`; do
    printf "*"
  done
  printf " $statusTxt: $functionTxt "
  for i in `seq 1 $numStarsEnd`; do
    printf "*"
  done
  printf "\n"
  for i in `seq 1 $lineLen`; do
    printf "*"
  done
  printf "\n"
}

usage(){
  echo "$0 <usage>"
  echo " "
  echo "options:"
  echo -e "--help \t Show options for this script"
  echo -e "--eBIP \t IP for the eB windows instance"
  echo -e "--CSIP \t IP for the CS windows instance"
  echo -e "--playbookurl \t Overwrite the default location for the playbook ZIP file"
  echo -e "--roleurl \t Overwrite the default location for the playbook ZIP file"
  echo -e "--ansibleuser \t User ID for Ansible on the windows server"
  echo -e "--ansiblepassword \t Password for Ansible on the windows server"
}

installGit(){
  echoProcessStatus "Begin" "installGit"
  # ensure git is installed
  sudo yum install -y git-all
  # add github to known hosts
  sudo ssh-keyscan github.com >> ~/.ssh/known_hosts
  # pull git repo
  sudo git clone https://github.com/iwasalive/ADLP $dir_git
  echoProcessStatus "Complete" "installGit"
}

getIPs(){
  echoProcessStatus "Begin" "getIPs"
  local AS_eB_InstanceID=$(aws autoscaling describe-auto-scaling-instances --region ca-central-1 --output text --query "AutoScalingInstances[?AutoScalingGroupName=='$AS_eB'].InstanceId")
  IPs_eB=$(aws ec2 describe-instances --region ca-central-1 --output text --instance-ids $AS_eB_InstanceID --query Reservations[].Instances[].PrivateIpAddress)

  local AS_CS_InstanceID=$(aws autoscaling describe-auto-scaling-instances --region ca-central-1 --output text --query "AutoScalingInstances[?AutoScalingGroupName=='$AS_CS'].InstanceId")
  IPs_CS=$(aws ec2 describe-instances --region ca-central-1 --output text --instance-ids $AS_CS_InstanceID --query Reservations[].Instances[].PrivateIpAddress)
  echoProcessStatus "Complete" "getIPs"
}

# Creates the basic folder structure for Ansible
createFolder(){
  [ -d $dir_ansible ] || mkdir $dir_ansible
  [ -d $dir_inventory ] || mkdir $dir_inventory
  [ -d $group_vars ] || mkdir $group_vars
  [ -d $dir_playbooks ] || mkdir $dir_playbooks
  [ -d $dir_roles ] || mkdir $dir_roles
  [ -d $dir_groupvars ] || mkdir $dir_groupvars
}

# Valdiates whether a string is formatted correctly as an IP
# Input: string
# Output: boolean
validateIP(){
  if [[ $1 =~ ipPattern ]]; then
    return 0
  else
    return 1
  fi
}

buildAnsibleConfig(){
  echoProcessStatus "Begin" "buildAnsibleConfig"
cat >> $file_config_ansible <<EOF
[defaults]
inventory = $file_inv_ansible
roles_path = $dir_roles
retry_files_enabled = False
log_path=$dir_log
EOF
  echoProcessStatus "Complete" "buildAnsibleConfig"
}

buildInventory(){
  echoProcessStatus "Begin" "buildInventory"
  getIPs

  if [[ "$AS_eB" == "" ]]; then
    echo "IP for eB virtual machine was not provided"
  elif validateIP $AS_eB; then
    echo "IP for eB virtual machine was not valid"
  fi

  if [ "$AS_CS" == "" ]; then
    echo "IP for CS virtual machine was not provided"
  elif validateIP $AS_CS; then
    echo "IP for CS virtual machine was not valid"
  fi

cat > $file_inv_ansible <<EOF
[all]
$IPs_eB
$IPs_CS

[eb]
$IPs_eB

[db]
$IPs_CS
EOF
  echoProcessStatus "Complete" "buildInventory"
}

# builds the variable files
buildVarsFiles(){
  echoProcessStatus "Begin" "buildVarsFiles"
#GroupVars all.yml file
cat > $file_inv_groupvars_all <<EOF
ansible_user: $ansible_user
ansible_password: $ansible_pass
ansible_port: 5986
ansible_connection: winrm
ansible_winrm_server_cert_validation: ignore
EOF
  echoProcessStatus "Complete" "buildVarsFiles"
}

# Copies and unpacks the playbooks
#
copyPlaybooks(){
  echoProcessStatus "Begin" "copyPlaybooks"
  #download file
  local filename=$(basename "$url_zip_playbook")
  wget -P $dir_playbooks $url_zip_playbook -O "$dir_playbooks/$filename"
  #unpack file to playbook directory
  unzip -d $dir_playbooks -o "$dir_playbooks/$filename"
  echoProcessStatus "Complete" "copyPlaybooks"
}

# Copies and unpacks the roles folders
#
copyRoles(){
  echoProcessStatus "Begin" "copyRoles"
  #download zip file
  local filename=$(basename "$url_zip_roles")
  wget -P $dir_roles $url_zip_roles -O "$dir_roles/$filename"
  #unpack file to roles directory
  unzip -d $dir_roles -o "$dir_roles/$filename"
  echoProcessStatus "Complete" "copyRoles"
}

# Runs the playbooks
runPlaybooks(){
  echoProcessStatus "Begin" "runPlaybooks"
  cd $dir_ansible
  ansible-playbook -vvvv $file_pb > $playbookLog
  echoProcessStatus "Complete" "runPlaybooks"
}

############################### End Functions Definition

# extract options and their arguments into variables.
while true; do
  case "$1" in
    -h | --help)
      usage
      exit 1
      ;;
    -eb | --eBAutoScalingGroup)
      AS_eB="$2";
      shift 2
      ;;
    -cs | --CSAutoScalingGroup)
      AS_CS="$2";
      shift 2
      ;;
    -pb | --playbookurl)
      url_zip_playbook="$2";
      shift 2
      ;;
    -role | --roleurl)
      url_zip_roles="$2";
      shift 2
      ;;
    -au | --ansibleuser)
      ansible_user="$2";
      shift 2
      ;;
    -ap | --ansiblepassword)
      ansible_pass="$2";
      shift 2
      ;;
    --)
      break
      ;;
    *)
      break
      ;;
  esac
done

# run script
installGit

#createFolder
buildAnsibleConfig
buildInventory
buildVarsFiles
#copyRoles
runPlaybooks
