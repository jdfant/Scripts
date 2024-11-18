#!/bin/bash

#Variables
K8S_VERSION="v1.29"
CRIO_VERSION="v1.29.0"
K8S_USER="k8s"
POD_CIDR="10.244.0.0/16"
NODENAME=$(hostname -s)
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CILIUM_CLI_ARCH=amd64
#CLUSTER_CIDR="10.96.0.0/28"

apt_prep(){
  apt-get -y update
  apt-get -y install \
    apt-transport-https \
    curl \
    jq \
    plocate \
    socat \
    software-properties-common
}

network_prep(){
  cat << EOF > /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

  sysctl --system
  modprobe overlay
  modprobe br_netfilter
}

disable_swap(){
  swapoff -a
  sed -i '/swap/ s/^#*/#/' /etc/fstab
}

setup_kubernetes(){
  local NODE_IF="$(ip a | awk '/2:/ { gsub(":", "");print $2}')"
  local NODE_IP="$(ip --json addr show "${NODE_IF}" | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"

  # Kubernetes, CRI-O, and Helm
  curl -fsSL https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key |
      gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" |
      tee /etc/apt/sources.list.d/kubernetes.list

  # CRI-O
  curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
      gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
      tee /etc/apt/sources.list.d/cri-o.list

  # Helm
  curl -fsSL https://baltocdn.com/helm/signing.asc |
      gpg --dearmor -o /usr/share/keyrings/helm.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" |
      tee /etc/apt/sources.list.d/helm-stable-debian.list

  apt-get update
  apt-get -y install \
    cri-o \
    helm \
    kubelet \
    kubeadm \
    kubectl
  apt-mark hold \
    kubelet \
    kubeadm \
    kubectl

  cat << EOF > /etc/default/kubelet
KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}
EOF

  systemctl daemon-reload
  systemctl enable crio --now
  systemctl enable kubelet
  systemctl start crio.service
  systemctl start kubelet

  # crictl
  curl -fsSLO https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRIO_VERSION}/crictl-${CRIO_VERSION}-linux-amd64.tar.gz
  tar xfz crictl-${CRIO_VERSION}-linux-amd64.tar.gz -C /usr/local/bin
  rm -f crictl-${CRIO_VERSION}-linux-amd64.tar.gz

  # Cilium
  helm repo add cilium https://helm.cilium.io/
  helm repo update

  curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CILIUM_CLI_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check cilium-linux-${CILIUM_CLI_ARCH}.tar.gz.sha256sum
  tar xvzfC cilium-linux-${CILIUM_CLI_ARCH}.tar.gz /usr/local/bin
  rm cilium-linux-${CILIUM_CLI_ARCH}.tar.gz{,.sha256sum}
}

apt_cleanup(){
    apt-get -y autoremove
    apt-get clean
    updatedb
}

init_cluster(){
  echo -e "\nCOPY THIS OUTPUT TO A SAFE PLACE \n"
  kubeadm init --pod-network-cidr=${POD_CIDR} --node-name "${NODENAME}" --ignore-preflight-errors Swap --skip-phases=addon/kube-proxy
  mkdir -p /home/${K8S_USER}/.kube
  cp -i /etc/kubernetes/admin.conf /home/${K8S_USER}/.kube/config
  chown -R "$(id -u ${K8S_USER})":"$(id -g ${K8S_USER})" /home/${K8S_USER}/.kube
}

case "$1" in
  control_plane)
      apt_prep
      network_prep
      set_swap
      set_selinux
      setup_docker
      setup_kubernetes
      apt_cleanup
      init_cluster
      ;;
  worker_node)
      apt_prep
      network_prep
      set_swap
      set_selinux
      setup_docker
      setup_kubernetes
      apt_cleanup
      ;;
  *)
      echo $"Usage: $0 {upload|download}"
      exit 1
esac

#Add Control Plane Nodes
# join_cluster(){
#  kubeadm join (YOURMASTERNODEIP):6443 - token (thetokendisplayed) \
#  - discovery-token-ca-cert-hash sha256:(thetokendisplayed)
# }

## Generate all necessary certs
## Execute on existing Control Plane Node
# kubeadm init phase certs all
# kubeadm init phase kubeconfig all

## Copy certs generated above ("/etc/kubernetes/pki") to new Control Plane Node
## Then, execute on new Control Plane Node
# kubeadm init phase control-plane all