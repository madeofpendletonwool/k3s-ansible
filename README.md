# Automated build of HA k3s Cluster on Talos with `kube-vip` and MetalLB

This is based on the work from [this fork](https://github.com/212850a/k3s-ansible) which is based on the work from [k3s-io/k3s-ansible](https://github.com/k3s-io/k3s-ansible).


## ✅ System requirements

- Control Node (the machine you are running `ansible` commands) must have Ansible 2.11+ If you need a quick primer on Ansible [you can check out my docs and setting up Ansible](https://technotim.live/posts/ansible-automation/).

- You will also need to install collections that this playbook uses by running `ansible-galaxy collection install -r ./collections/requirements.yml` (important❗)

- [`netaddr` package](https://pypi.org/project/netaddr/) must be available to Ansible. If you have installed Ansible via apt, this is already taken care of. If you have installed Ansible via `pip`, make sure to install `netaddr` into the respective virtual environment.

- `server` and `agent` nodes should have passwordless SSH access, if not you can supply arguments to provide credentials `--ask-pass --ask-become-pass` to each command.

## 🚀 Getting Started

### 🍴 Preparation

First create a new directory based on the `sample` directory within the `inventory` directory:

```bash
cp -R inventory/sample inventory/my-cluster
```

Finally, copy `ansible.example.cfg` to `ansible.cfg` and adapt the inventory path to match the files that you just created.

This requires at least k3s version `1.19.1` however the version is configurable by using the `k3s_version` variable.

If needed, you can also edit `inventory/my-cluster/group_vars/all.yml` to match your environment.

### ☸️ Create Cluster and deploy stuff

- Setup proxmox nodes in hosts
- Setup Env vars
- Deploy talos servers to prox hosts
```
ansible-playbook talos-deploy.yml -i inventory/hosts.ini --ask-become-pass 
```
- Get ips of talos servers and add to hosts file
- Configure talos
```
ansible-playbook talos-configuration.yml -i inventory/hosts.ini --ask-become-pass 
```
- Setup all the depends

```
ansible-playbook metallb.yml -i inventory/hosts.ini --ask-become-pass 
```

```
ansible-playbook rook-ceph.yml -i inventory/hosts.ini --ask-become-pass 
```

```
ansible-playbook traefik.yml -i inventory/hosts.ini --ask-become-pass 
```

#### Now deploy apps you want

```
ansible-playbook ntfy.yml -i inventory/hosts.ini --ask-become-pass 
```

```
ansible-playbook uptime-kuma.yml -i inventory/hosts.ini --ask-become-pass 
```

```
ansible-playbook jellyfin.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook navidrome.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook immich.yml -i inventory/hosts.ini --ask-become-pass 
```

```
ansible-playbook pinepods.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook navidrome.yml -i inventory/hosts.ini --ask-become-pass 
```


### 🔥 Remove k3s cluster

```bash
ansible-playbook reset.yml -i inventory/my-cluster/hosts.ini
```

>You should also reboot these nodes due to the VIP not being destroyed

## ⚙️ Kube Config

To copy your `kube config` locally so that you can access your **Kubernetes** cluster run:

```bash
scp debian@master_ip:/etc/rancher/k3s/k3s.yaml ~/.kube/config
```
If you get file Permission denied, go into the node and temporarly run:
```bash
sudo chmod 777 /etc/rancher/k3s/k3s.yaml
```
Then copy with the scp command and reset the permissions back to:
```bash
sudo chmod 600 /etc/rancher/k3s/k3s.yaml
```

You'll then want to modify the config to point to master IP by running:
```bash
sudo nano ~/.kube/config
```
Then change `server: https://127.0.0.1:6443` to match your master IP: `server: https://192.168.1.222:6443`

### 🔨 Testing your cluster

See the commands [here](https://technotim.live/posts/k3s-etcd-ansible/#testing-your-cluster).

### Troubleshooting

Be sure to see [this post](https://github.com/techno-tim/k3s-ansible/discussions/20) on how to troubleshoot common problems

### Testing the playbook using molecule

This playbook includes a [molecule](https://molecule.rtfd.io/)-based test setup.
It is run automatically in CI, but you can also run the tests locally.
This might be helpful for quick feedback in a few cases.
You can find more information about it [here](molecule/README.md).

### Pre-commit Hooks

This repo uses `pre-commit` and `pre-commit-hooks` to lint and fix common style and syntax errors.  Be sure to install python packages and then run `pre-commit install`.  For more information, see [pre-commit](https://pre-commit.com/)

## 🌌 Ansible Galaxy

This collection can now be used in larger ansible projects.

Instructions:

- create or modify a file `collections/requirements.yml` in your project

```yml
collections:
  - name: ansible.utils
  - name: community.general
  - name: ansible.posix
  - name: kubernetes.core
  - name: https://github.com/techno-tim/k3s-ansible.git
    type: git
    version: master
```

- install via `ansible-galaxy collection install -r ./collections/requirements.yml`
- every role is now available via the prefix `techno_tim.k3s_ansible.` e.g. `techno_tim.k3s_ansible.lxc`

## Thanks 🤝

This repo is really standing on the shoulders of giants. Thank you to all those who have contributed and thanks to these repos for code and ideas:

- [k3s-io/k3s-ansible](https://github.com/k3s-io/k3s-ansible)
- [geerlingguy/turing-pi-cluster](https://github.com/geerlingguy/turing-pi-cluster)
- [212850a/k3s-ansible](https://github.com/212850a/k3s-ansible)




## General hip tips

# Kubernetes Cluster Management Commands Reference

## MetalLB & Service Access
```bash
# Get all LoadBalancer services and their IPs across all namespaces
kubectl get svc -A --output=custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,EXTERNAL-IP:.status.loadBalancer.ingress[0].ip,PORTS:.spec.ports[*].port" | grep LoadBalancer

# Get a nicely formatted list of all LoadBalancer services with connection details
kubectl get svc -A -o=jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{"\nNamespace: "}{.metadata.namespace}{"\nService: "}{.metadata.name}{"\nExternal IP: "}{.status.loadBalancer.ingress[0].ip}{"\nPorts: "}{range .spec.ports[*]}{"\n  - "}{.port}{" ("}{.protocol}{")"}{end}{"\n"}{end}'

# Check MetalLB speaker and controller status
kubectl get pods -n metallb-system
```

## Rook-Ceph Storage Cluster
```bash
# Get Ceph cluster status
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l app=rook-ceph-tools -o name) -- ceph status

# Check Ceph cluster health
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l app=rook-ceph-tools -o name) -- ceph health detail

# List all OSDs and their nodes
kubectl -n rook-ceph get pods -l app=rook-ceph-osd -o wide

# Get storage node information
kubectl get nodes -l topology.kubernetes.io/zone=onsite

# Check Ceph pool status
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l app=rook-ceph-tools -o name) -- ceph df

# List PVCs and their status
kubectl get pvc --all-namespaces

# Check StorageClasses
kubectl get storageclass
```

## Traefik Management
```bash
# Get Traefik pod status
kubectl get pods -n ingress-traefik

# Get Traefik services and their IPs
kubectl get svc -n ingress-traefik

# Check Traefik logs
kubectl logs -n ingress-traefik -l app=traefik --tail=100

# List all Ingress resources
kubectl get ingress --all-namespaces

# Check Traefik CRDs
kubectl get ingressroute,middleware,tlsoption,tlsstore --all-namespaces
```

## Node Management
```bash
# Get node status with labels
kubectl get nodes --show-labels

# Check node resource allocation
kubectl describe nodes | grep -A 5 "Allocated resources"

# List pods on specific node
kubectl get pods --all-namespaces -o wide --field-selector spec.nodeName=<node-name>

# Get node topology information
kubectl get nodes -L topology.kubernetes.io/zone
```

## Pod & Container Health
```bash
# Get failing pods across all namespaces
kubectl get pods --all-namespaces | grep -v "Running\|Completed"

# Show pod resource usage
kubectl top pods --all-namespaces

# Show node resource usage
kubectl top nodes

# Get events sorted by timestamp
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

## Storage Troubleshooting
```bash
# Check Ceph component versions
kubectl -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l app=rook-ceph-tools -o name) -- ceph versions

# Get Rook-Ceph operator logs
kubectl logs -n rook-ceph -l app=rook-ceph-operator

# Check CSI driver status
kubectl get pods -n rook-ceph -l app=csi-rbdplugin
kubectl get pods -n rook-ceph -l app=csi-cephfsplugin

# List all PVs and their status
kubectl get pv
```

## Helpful One-Liners
```bash
# Watch pod creation/deletion across all namespaces
watch 'kubectl get pods --all-namespaces | grep -v "Running\|Completed"'

# Get all resources in a namespace
kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>

# Quick cluster health check
kubectl get nodes,pv,pvc,storageclass && kubectl get pods --all-namespaces | grep -v "Running\|Completed"
```

## Common Port References
- Traefik Dashboard: 8080
- Traefik Web: 80, 443
- Ceph Dashboard: 7000

## Namespace Quick Reference
- ingress-traefik: Traefik ingress controller
- rook-ceph: Ceph storage cluster
- metallb-system: MetalLB load balancer