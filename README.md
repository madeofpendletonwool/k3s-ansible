# Automated build of HA k3s Cluster on Talos with `kube-vip` and MetalLB

This is based on the work from [this fork](https://github.com/212850a/k3s-ansible) which is based on the work from [k3s-io/k3s-ansible](https://github.com/k3s-io/k3s-ansible).

## 🚀 Getting Started

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
freshrss
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
ansible-playbook log-stack.yml -i inventory/hosts.ini --ask-become-pass 
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
ansible-playbook opodsync.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook syncthing.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook freshrss.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook freshrss.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook searxng.yml -i inventory/hosts.ini --ask-become-pass 
```

#### WIP

```
ansible-playbook minecraft-server.yml -i inventory/hosts.ini --ask-become-pass 
```
```
ansible-playbook terraria-server.yml -i inventory/hosts.ini --ask-become-pass 
```


### 🔥 Remove k3s cluster

#### WIP

```bash
ansible-playbook reset.yml -i inventory/my-cluster/hosts.ini
```

>You should also reboot these nodes due to the VIP not being destroyed

## ⚙️ Kube Config

kubeconfig will be local after deploying and can be accessed with 

```
export KUBECONFIG="/tmp/talos-kubeconfig"
```
Now kubectl commands will work


## General Hip Tips - Kubernetes Cluster Management Commands Reference

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

## Namespace Quick Reference
- ingress-traefik: Traefik ingress controller
- rook-ceph: Ceph storage cluster
- metallb-system: MetalLB load balancer
- freshrss: Freshrss rss Agregator
- immich: Immich Image Server
- jellyfin: Jellyfin Media Server
- log-stack: Prometheus stack with Grafana and Alert Manager
- navidrome: Navidrome Music Server
- ntfy: ntfy Notification platform
- pinepods: Pinepods Podcast Server
- uptime-kuma: Uptime Kuma Monitoring


## Domains quick reference

jellyfin.mysite.com
grafana.mysite.com
prometheus.mysite.com
alertmangaer.mysite.com
rss.mysite.com
pics.mysite.com
ntfy.mysite.com
podsync.mysite.com
pinepods.mysite.com
people.mysite.com
search.mysite.com
search.myothersite.com


