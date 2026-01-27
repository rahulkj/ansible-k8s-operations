#!/bin/bash

SSH_PASS_EXISTS=$(which sshpass)

USER_VARIABLES=(PI_USER VM_USER)
PASSWORD_VARIABLES=(PI_PASSWORD PI_SUDO_PASSWORD VM_PASSWORD VM_SUDO_PASSWORD)

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

usage_instructions() {
    echo "Usage: ./run-ansible.sh <OPTION> <SUB-OPTION>"
    echo "  Options:"
    echo "    k8s-bootstrap: bootstrap k8s environment"
    echo "    k8s-destroy: destroy k8s environment"
    echo "    k8s-upgrade: upgrade k8s environment"
    echo "    k8s-upgrade-packages: upgrade k8s packages to the latest version"
    echo
    echo "  Sub-Options:"
    echo "    pi: operate on Raspberry Pi based lab environment"
    echo "    vm: operate on VM based lab environment"
    echo
    echo "  Example:"
    echo "    ./run-ansible.sh k8s-bootstrap pi"
    echo "    ./run-ansible.sh k8s-destroy vm"
    echo "    ./run-ansible.sh k8s-upgrade pi"
    echo "    ./run-ansible.sh k8s-upgrade-packages vm"
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

echo "----- Generate the inventory yaml file -----"
cleanupFile

if [[ -z "$1" ]]; then
    usage_instructions
    exit 1
fi

case $1 in
    k8s-bootstrap)
        case $2 in
            pi)
                export IP_POOL=$PI_IP_POOL
                ;;
            vm)
                export IP_POOL=$VM_IP_POOL
                ;;
            *)
                usage_instructions
                exit 1
                ;;
        esac

        export PLATFORM="$2"

        envsubst < templates/metal-lb-config.yaml > temp/metal-lb-config.yaml
        envsubst < templates/headlamp-ingress.yaml > temp/headlamp-ingress.yaml                
        envsubst < config/$2-k8s-inventory.yaml > temp/inventory-updated.yaml

        ansible-playbook playbooks/setup-k8s-playbook.yaml -i temp/inventory-updated.yaml
        ;;
    k8s-destroy)
        case $2 in
            pi|vm)
                envsubst < config/$2-k8s-inventory.yaml > temp/inventory-updated.yaml
                ansible-playbook playbooks/reset-k8s-playbook.yaml -i temp/inventory-updated.yaml
                ;;
            *)
                usage_instructions
                exit 1
                ;;
        esac
        ;;
    k8s-upgrade)
        case $2 in
            pi|vm)
                envsubst < config/$2-k8s-inventory.yaml > temp/inventory-updated.yaml
                ansible-playbook playbooks/upgrade-k8s-playbook.yaml -i temp/inventory-updated.yaml
                ;;
            *)
                usage_instructions
                exit 1
                ;;
        esac
        ;;
    k8s-upgrade-packages)
        case $2 in
            pi)
                export IP_POOL=$PI_IP_POOL
                ;;
            vm)
                export IP_POOL=$VM_IP_POOL
                ;;
            *)
                usage_instructions
                exit 1
                ;;
        esac

        export PLATFORM="$2"

        envsubst < templates/metal-lb-config.yaml > temp/metal-lb-config.yaml
        envsubst < templates/headlamp-ingress.yaml > temp/headlamp-ingress.yaml
        envsubst < config/$2-k8s-inventory.yaml > temp/inventory-updated.yaml

        ansible-playbook playbooks/upgrade-k8s-packages-playbook.yaml -i temp/inventory-updated.yaml
        ;;
    *)
        usage_instructions
        exit 1
        ;;
esac
;;

cleanupFile