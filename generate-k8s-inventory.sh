#!/bin/bash

FILE=""

if [[ $1 == "pi" ]]; then
    IFS=', ' read -r -a control_plane_hosts <<< "$PI_CONTROL_PLANE_HOSTS"
    IFS=', ' read -r -a worker_hosts <<< "$PI_WORKER_HOSTS"
    FILE="config/pi-k8s-inventory.yaml"
elif [[ $1 == "vms" ]]; then
    IFS=', ' read -r -a control_plane_hosts <<< "$VM_CONTROL_PLANE_HOSTS"
    IFS=', ' read -r -a worker_hosts <<< "$VM_WORKER_HOSTS"
    FILE="config/vms-k8s-inventory.yaml"
else
    echo "invalid option, the only support options are pi/vms"
    echo "./generate-k8s-inventory.sh <OPTION>"
    echo "pi: generate the inventory for raspberry pi's"
    echo "vms: generate the inventory for vms"
    exit 1
fi

all_str=""
control_plane_str=""
worker_str=""

for host in ${control_plane_hosts[@]}; do
    if [[ ! -z $all_str ]]; then
        all_str+=" | "
    fi

    if [[ ! -z $control_plane_str ]]; then
        control_plane_str+=" | "
    fi

    if [[ $1 == "pi" ]]; then
        all_str+="(.all.hosts.$host.ansible_host=\"$host\" | \
            .all.hosts.$host.ansible_user=\"\$PI_USER\" | \
            .all.hosts.$host.ansible_ssh_pass=\"\$PI_PASSWORD\" | \
            .all.hosts.$host.ansible_become=\"yes\" | \
            .all.hosts.$host.ansible_become_method=\"sudo\" | \
            .all.hosts.$host.ansible_become_password=\"\$PI_SUDO_PASSWORD\")"
        control_plane_str+="(.control_plane.hosts.$host.ansible_host=\"$host\" | 
            .control_plane.hosts.$host.ansible_user=\"\$PI_USER\" | \
            .control_plane.hosts.$host.ansible_ssh_pass=\"\$PI_PASSWORD\" | \
            .control_plane.hosts.$host.ansible_become=\"yes\" | \
            .control_plane.hosts.$host.ansible_become_method=\"sudo\" | \
            .control_plane.hosts.$host.ansible_become_password=\"\$PI_SUDO_PASSWORD\")"
    elif [[ $1 == "vms" ]]; then
        all_str+="(.all.hosts.$host.ansible_host=\"$host\" | \
            .all.hosts.$host.ansible_user=\"\$VM_USER\" | \
            .all.hosts.$host.ansible_ssh_pass=\"\$VM_PASSWORD\" | \
            .all.hosts.$host.ansible_become=\"yes\" | \
            .all.hosts.$host.ansible_become_method=\"sudo\" | \
            .all.hosts.$host.ansible_become_password=\"\$VM_SUDO_PASSWORD\")"
        control_plane_str+="(.control_plane.hosts.$host.ansible_host=\"$host\" | 
            .control_plane.hosts.$host.ansible_user=\"\$VM_USER\" | \
            .control_plane.hosts.$host.ansible_ssh_pass=\"\$VM_PASSWORD\" | \
            .control_plane.hosts.$host.ansible_become=\"yes\" | \
            .control_plane.hosts.$host.ansible_become_method=\"sudo\" | \
            .control_plane.hosts.$host.ansible_become_password=\"\$VM_SUDO_PASSWORD\")"
    fi
done

for host in ${worker_hosts[@]}; do
    if [[ ! -z $all_str ]]; then
        all_str+=" | "
    fi

    if [[ ! -z $worker_str ]]; then
        worker_str+=" | "
    fi

    if [[ $1 == "pi" ]]; then
        all_str+="(.all.hosts.$host.ansible_host=\"$host\" | \
            .all.hosts.$host.ansible_user=\"\$PI_USER\" | \
            .all.hosts.$host.ansible_ssh_pass=\"\$PI_PASSWORD\" | \
            .all.hosts.$host.ansible_become=\"yes\" | \
            .all.hosts.$host.ansible_become_method=\"sudo\" | \
            .all.hosts.$host.ansible_become_password=\"\$PI_SUDO_PASSWORD\")"
        worker_str+="(.worker_str.hosts.$host.ansible_host=\"$host\" | 
            .worker_str.hosts.$host.ansible_user=\"\$PI_USER\" | \
            .worker_str.hosts.$host.ansible_ssh_pass=\"\$PI_PASSWORD\" | \
            .worker_str.hosts.$host.ansible_become=\"yes\" | \
            .worker_str.hosts.$host.ansible_become_method=\"sudo\" | \
            .worker_str.hosts.$host.ansible_become_password=\"\$PI_SUDO_PASSWORD\")"
    elif [[ $1 == "vms" ]]; then
        all_str+="(.all.hosts.$host.ansible_host=\"$host\" | \
            .all.hosts.$host.ansible_user=\"\$VM_USER\" | \
            .all.hosts.$host.ansible_ssh_pass=\"\$VM_PASSWORD\" | \
            .all.hosts.$host.ansible_become=\"yes\" | \
            .all.hosts.$host.ansible_become_method=\"sudo\" | \
            .all.hosts.$host.ansible_become_password=\"\$VM_SUDO_PASSWORD\")"
        worker_str+="(.worker_str.hosts.$host.ansible_host=\"$host\" | 
            .worker_str.hosts.$host.ansible_user=\"\$VM_USER\" | \
            .worker_str.hosts.$host.ansible_ssh_pass=\"\$VM_PASSWORD\" | \
            .worker_str.hosts.$host.ansible_become=\"yes\" | \
            .worker_str.hosts.$host.ansible_become_method=\"sudo\" | \
            .worker_str.hosts.$host.ansible_become_password=\"\$VM_SUDO_PASSWORD\")"
    fi
done

str+="$all_str"
str+="|"
str+="$control_plane_str"
str+="|"
str+="$worker_str"

yq --null-input "$str" > $FILE