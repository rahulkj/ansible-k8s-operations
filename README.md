Ansible playbook for managing k8s ops
---

This repo will help you bootstrap or destroy the k8s clusters that are provisioned on you raspberry Pi's or vms using kubeadm. This automation will deploy all k8s components, and its not like k3s or microk8s.

### Pre-requsities
* Install all the required cli's on your mac
  * ansible
  * direnv
* Update the [.envrc](./.envrc) file with your hosts names, username and passwords
* Generate the inventory yaml using the script `./generate-k8s-inventory.sh`, that will generate the inventory files in the [config](./config/) folder
* Validate and update the inventory [yamls](./config) if setting up on vms or k8s

### Bootstrap k8s on pi/vms
To do this, its simple, just run the script `./run-anisble.sh` with the appropriate options

```
./run-ansible.sh k8s-bootstrap
Usage: ./run-ansible.sh k8s-bootstrap <OPTION>
pi: bootstrap k8s environment on pi
vms: bootstrap k8s environment on vms
```

Once done, you can ssh into the control_plane vm/s, and run the following commands:

```
ok: [k8s-node-1] => {
    "msg": [
        "SSH to the host, and run the commands",
        "mkdir -p $HOME/.kube",
        "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
        "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
    ]
}
```

The following are provisioned:
* Kubernetes cluster
* CNI - canal
* conatinerd
* metallb
* kubernetes dashboard
* nfs storage provider using your nfs configuration
* nginx ingress controller

### Destroy k8s on pi/vms
Its similar to bootstrapping, but the command and options are different

```
./run-ansible.sh k8s-destroy
Usage: ./run-ansible.sh k8s-destroy <OPTION>
pi: destroy k8s environment on pi
vms: destroy k8s environment on vms
```

Enjoy!