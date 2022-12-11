#!/bin/bash

print_header()
{
printf "#%0.s" $(seq 1 $(tput cols))
printf "\n"
}

center_msg()
{
msg=$1
terminalcol=$(tput cols)
msg_len=$(echo ${#1})
pre_space=$(($((terminalcol-msg_len))/2))

print_header
printf " %0.s" $(seq 1 $pre_space)
printf "%s" "$1"
printf "\n"
print_header
}

check_remotepass()
{
if [ ! -e "remotepass" ]
then
center_msg "Please store your password in >>remotepass<< file and retry"
exit 1
fi
}

check_remoteuser()
{
if [ ! -e "remoteuser" ]
then
center_msg "Please store your remote user name in >>remoteuser<< file and retry"
exit 2
fi
}

check_list_of_server()
{
if [ ! -e "list_of_server" ]
then
center_msg "Please store your remote server host name or ip in >>list_of_server<< file and retry"
exit 3
fi
}

check_sshpass()
{
which sshpass
if [ $? -ne 0 ]
then
echo "SSHPASS Installing for automate Login......"
sudo apt install -y sshpass
else
echo "SSHPASS already install"
fi
}
center_msg "Welcome to Inventory Script"
check_remotepass
check_remoteuser
check_list_of_server
check_sshpass
ssh_opt="sshpass -f remotepass ssh -n -o StrictHostKeyChecking=No -o PubkeyAuthentication=No $(cat remoteuser)"
echo "Server_Name,OS_TYPE,OS_VERSION,CPU_MODEL,CPU_CORES,RAM_USAGE,SWAP_USAGE,HDD_USAGE" > serverinfo.csv
while read server
do
echo "Working on $server"
OS_TYPE=$($ssh_opt@$server "cat /etc/os-release" | grep -w "NAME" | awk -F "NAME=" '{print $2}' | tr '"' " ")
echo "$OS_TYPE" | grep -i "ubuntu" 1>/dev/null 2>&1
if [ $? -eq 0 ]
then
OS_VERSION=$($ssh_opt@$server "cat /etc/os-release" | grep "VERSION_ID" | awk -F "VERSION_ID=" '{print $2}')
else
OS_VERSION=$($ssh_opt@$server "cat /etc/redhat-release" | awk -F "release" '{print $2}' | awk '{print $1}')
fi
CPU_MODEL=$($ssh_opt@$server "cat /proc/cpuinfo" | grep "model name" | head -n1 | awk -F "model name" '{print $2}' | tr ':' " " | sed -E 's/[[:space:]]+/ /')
CPU_CORES=$($ssh_opt@$server "cat /proc/cpuinfo" | grep "cpu cores" |head -n1 | awk -F "cpu cores" '{print $2}' | tr ':' " " |sed -E 's/[[:space:]]+/ /')
RAM_USAGE=$($ssh_opt@$server "free -m" | awk 'NR==2{printf "RAM Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }')
SWAP_USAGE=$($ssh_opt@$server "free -m" | awk 'NR==3{printf "SWAP Memory Usage: %s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }')
HDD_USAGE=$($ssh_opt@$server "df -h" | awk '$NF=="/"{printf "Disk Usage: %s/%sB (%s)\n", $3,$2,$5}')
echo "OS_TYPE=$OS_TYPE"
echo "OS_VERSION=${OS_VERSION}"
echo "CPU_MODEL=$CPU_MODEL"
echo "CPU_CORES=${CPU_CORES}"
echo "$RAM_USAGE"
echo "$SWAP_USAGE"
echo "$HDD_USAGE"
echo "$server,$OS_TYPE,$OS_VERSION,$CPU_MODEL,${CPU_CORES},$RAM_USAGE,$SWAP_USAGE,$HDD_USAGE" >> serverinfo.csv
done < list_of_server