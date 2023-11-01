#!/bin/bash
## Install Kubernetes v1.28 on Ubuntu LTS using kubeadm

## Check if not run as root
if [ "$EUID" -eq 0 ]; then
  echo Run this script as a regular user.
  exit 1
fi

## Check if it is Ubuntu
source /etc/os-release
if [ "$ID" != "ubuntu" ]; then
  echo This script should be run on Ubuntu.
  exit 1
fi

## Define Variables
# User Prompts
read -p "This script will install Kubernetes v1.28 with Calico on Ubuntu LTS. Press Enter to continue."
read -p "Have you set the correct hostname? [y/n] : " ISHOSTSET

# Set hostname if it not set
if [ $ISHOSTSET == 'n' ]; then
  read -p "Enter the hostname to set: " HOST
  sudo hostnamectl set-hostname ${HOST}
  sudo sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost ${HOST}/" /etc/hosts
  sudo reboot
fi

read -p "Is this the master node? [y/n]: " IS_MASTER
IS_MASTER=${IS_MASTER:-n}

# Update the Pod Subnet if the user wants to, for the master node
if [ ${IS_MASTER} == 'y' ]; then
  POD_SUBNET="172.16.0.0/16"
  read -p "The Pod CIDR is ${POD_SUBNET}. Press Enter to continue or c to change: " CHANGE
  if [ ! -z $CHANGE ]; then
    read -p "Enter the Pod CIDR to use with kubeadm: " POD_SUBNET
  fi
fi

# Restart services automatically instead of prompting the user
if [ "$UBUNTU_CODENAME" == "jammy" ]; then
  echo setting NEEDRESTART to auto...
  sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf
fi

# Update repos
sudo apt update

# Disable Swap if it exists
if [ ! -z $(swapon -s) ]; then
  echo Disable Swap Memory...
  sudo swapoff -a &> /dev/null
  sudo sed -i '/swap/d' /etc/fstab
fi

echo Forwarding IPv4 and letting iptables see bridged traffic...
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

echo Installing dependencies...
sudo apt update
sudo apt install -y ca-certificates curl gnupg bash-completion
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo Adding the Docker repository...
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

echo Installing containerd...
sudo apt install -y containerd.io

echo Configuring containerd for Kubernetes...
sudo su -c 'containerd config default > /etc/containerd/config.toml'
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

echo Installing kubelet, kubeadm and kubectl...
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Stop script if this is a worker node
if [ ${IS_MASTER} == 'n' ]; then
  echo Now join the worker node to the cluster using the 'kubeadm join' command from the master node.
  exit 0
fi

echo Initializing the control plane...
sudo kubeadm init --pod-network-cidr=${POD_SUBNET} |& tee kubeadm.log

# kubeconfig setup
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo Installing the Tigera Calico operator...
sleep 5
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml

# Download Calico Custom resource
curl -O --ssl https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/custom-resources.yaml

# Before creating this manifest, read its contents and make sure its settings are correct for your environment. For example, you may need to change the default IP pool CIDR to match your pod network CIDR.
sed -i "s|cidr: 192.168.0.0/16|cidr: ${POD_SUBNET}|g" custom-resources.yaml

echo Installing Calico...
sleep 5
kubectl create -f custom-resources.yaml

echo Installing Bash completion...
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo chmod a+r /etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc

# Display the join command for the worker nodes
tail -4 kubeadm.log
exit 0
