unset KUBECONFIG

multipass launch --name k3s-master-node --cpus 1 --mem 1024M --disk 3G
multipass launch --name k3s-worker-node-1 --cpus 1 --mem 1024M --disk 3G
multipass launch --name k3s-worker-node-2 --cpus 1 --mem 1024M --disk 3G

# install k3s on master node
multipass exec k3s-master-node -- /bin/bash -c "curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -"

# master node ip address 
K3S_MASTER_NODE_IP=$(multipass info k3s-master-node | grep IPv4 | awk '{print $2}')

# master node token for worker nodes to join cluster
K3S_MASTER_NODE_TOKEN=$(multipass exec k3s-master-node sudo cat /var/lib/rancher/k3s/server/node-token)

# install k3s on node 1 and join master on cluster
multipass exec k3s-worker-node-1 -- bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$K3S_MASTER_NODE_IP:6443\" K3S_TOKEN=\"$K3S_MASTER_NODE_TOKEN\" sh -"

# install k3s on node 2 and join master node on cluster
multipass exec k3s-worker-node-2 -- bash -c "curl -sfL https://get.k3s.io | K3S_URL=\"https://$K3S_MASTER_NODE_IP:6443\" K3S_TOKEN=\"$K3S_MASTER_NODE_TOKEN\" sh -"

# copy cluster configuration from master node to host
multipass exec k3s-master-node sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml

# replace the localhost with master node ip address
sed -i "s/127.0.0.1/$K3S_MASTER_NODE_IP/" k3s.yaml

# set current context to point to k3s cluster 
export KUBECONFIG=$PWD/k3s.yaml


# wait for cluster synchronization 
sleep 10s

# test 
kubectl get nodes -o wide
