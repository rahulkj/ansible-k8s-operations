#!/bin/bash

SSH_PASS_EXISTS=$(which sshpass)

USER_VARIABLES=(LINUX_VM_USER PI_VM_USER)
PASSWORD_VARIABLES=(LINUX_VM_PASSWORD LINUX_VM_SUDO_PASSWORD PI_VM_PASSWORD PI_VM_SUDO_PASSWORD)

if [[ -z $SSH_PASS_EXISTS ]]; then
    OS=$(uname)
    if [[ $OS == "Darwin" ]]; then
        brew tap esolitos/ipa
        brew install esolitos/ipa/sshpass
    elif [[ "$OS" == "Linux" ]]; then
        sudo apt install sshpass
    fi
fi

cleanupFile() {
    if [ -f temp/inventory-updated.yaml ]; then
        rm -f ./temp/*.yaml
    fi
}

promptUserInput() {
    export $1
    read -s -p "Enter username for $1: " $1
    echo
}

promptPasswordInput() {
    export $1
    read -s -p "Enter password for $1: " $1
    echo
}

for v in ${PASSWORD_VARIABLES[@]}; do
    if [ -z $(env | grep $v) ]; then
        promptPasswordInput $v
    else
        VARIABLE=$(env | grep $v)
        VALUE=$(echo $VARIABLE | cut -d '=' -f2)
        if [ -z $VALUE ]; then
            promptPasswordInput $v
        fi
    fi
done

for v in ${USER_VARIABLES[@]}; do
    if [ -z $(env | grep $v) ]; then
        promptUserInput $v
    else
        VARIABLE=$(env | grep $v)
        VALUE=$(echo $VARIABLE | cut -d '=' -f2)
        if [ -z $VALUE ]; then
            promptUserInput $v
        fi
    fi
done

cleanupFile

if [[ -z "$1" ]]; then
    echo "Usage: ./run-ansible.sh <OPTION>"
    echo "k8s-bootstrap: setup k8s environment"
    echo "k8s-destroy: reset the machines that have k8s cluster"
    exit 1
fi

if [[ "$1" == "k8s-bootstrap" ]]; then
    if [[ "$2" == "pi" ]]; then
        export IP_POOL=$PI_IP_POOL
        envsubst < templates/metal-lb-config.yaml > temp/metal-lb-config.yaml

        echo "----- Generate the inventory yaml file -----"
        envsubst < config/$2-k8s-inventory.yaml > temp/inventory-updated.yaml
        ansible-playbook playbooks/setup-k8s-playbook.yaml -i temp/inventory-updated.yaml
    elif [[ "$2" == "vm" ]]; then
        export IP_POOL=$VMS_IP_POOL
        envsubst < templates/metal-lb-config.yaml > temp/metal-lb-config.yaml

        echo "----- Generate the inventory yaml file -----"
        envsubst < templates/$2-k8s-inventory.yaml > temp/inventory-updated.yaml
        ansible-playbook config/setup-k8s-playbook.yaml -i temp/inventory-updated.yaml
    else
        echo "Usage: ./run-ansible.sh k8s-bootstrap <OPTION>"
        echo "pi: bootstrap k8s environment on pi"
        echo "vm: bootstrap k8s environment on vm"
        exit 1
    fi
elif [[ "$1" == "k8s-destroy" ]]; then
    if [[ "$2" == "pi" ]]; then
        echo "----- Generate the inventory yaml file -----"
        envsubst < config/$2-k8s-inventory.yaml > temp/inventory-updated.yaml
        ansible-playbook playbooks/reset-k8s-playbook.yaml -i temp/inventory-updated.yaml
    elif [[ "$2" == "vm" ]]; then
        echo "----- Generate the inventory yaml file -----"
        envsubst < config/$2-k8s-inventory.yaml > temp/inventory-updated.yaml
        ansible-playbook playbooks/reset-k8s-playbook.yaml -i temp/inventory-updated.yaml
    else
        echo "Usage: ./run-ansible.sh k8s-destroy <OPTION>"
        echo "pi: destroy k8s environment on pi"
        echo "vm: destroy k8s environment on vm"
        exit 1
    fi
else 
    echo "You need to read the instructions properly"
fi