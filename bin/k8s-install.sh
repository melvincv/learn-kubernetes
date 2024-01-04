#!/bin/bash
## Interactive Script: Install (last 4 minor versions of) Kubernetes on Ubuntu LTS using kubeadm

## Call Libraries
. ./multi-k8s-install.lib

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

### Define Variables ###################################################

# Pod CIDR
POD_SUBNET="172.16.0.0/16"

# User Prompts
echo "If you need HA for the control plane, create a Load Balancer and get it's DNS name and port."
read -p "This script will install Kubernetes with Calico on Ubuntu LTS. Press Enter to continue."
read -p "Have you set the correct hostname? [y/n] : " ISHOSTSET

# Function call to set hostname and reboot if needed
if [ $ISHOSTSET == 'n' ]; then
  sethostname
elif [ -z $ISHOSTSET ]; then
  exit 1
fi

# Kubernetes Version Menu
echo "*** Kubernetes Version List ***"
echo "1) 1.29"
echo "2) 1.28"
echo "3) 1.27"
echo "4) 1.26"
echo ---
read -p "Select your Kubernetes Version [1-4] : " VER

# Check if VER is null, less than 1 or greater than 4
if [ -z "$VER" ] || [ $VER -lt 1 ] || [ $VER -gt 4 ]; then
    echo "$VER is not a valid Kubernetes version. Choose between 1 to 4"
    exit 1
fi

read -p "Is this the master node? [y/n]: " IS_MASTER
# Default Option: n
IS_MASTER=${IS_MASTER:-n}

# Ask for High Availability (function call)
masterhaprompt

### Define Variables End ###############################################

# Function call
# Update the Pod Subnet if the user wants to, for the master node
updatepodsubnet

# Function call
# Restart services automatically instead of prompting the user
needrestart

# Update repos
sudo apt update

# Function calls
# Disable Swap if it exists
disableswap

# Kernel parameter setup
kernelparamsetup
sudo sysctl --system

# Install containerd
installcontainerd

# Installing kubelet, kubeadm and kubectl...
echo
echo Installing kubelet, kubeadm and kubectl...

# In releases older than Debian 12 and Ubuntu 22.04, /etc/apt/keyrings does not exist by default
if [ ! -d /etc/apt/keyrings ]; then
    sudo mkdir -m 755 /etc/apt/keyrings
fi

# Kubernetes Repo Add
case $VER in
  1) installk8s-129 ;;
  2) installk8s-128 ;;
  3) installk8s-127 ;;
  4) installk8s-126 ;;
  *) echo "Invalid k8s version"; exit 1 ;;
esac

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Stop script if this is a worker node
if [ ${IS_MASTER} == 'n' ]; then
  echo Now join the worker node to the cluster using the 'kubeadm join' command from the master node.
  exit 0
fi

echo
echo Initializing the control plane...

if [ ${HA_MASTER} == "n" ]; then
  sudo kubeadm init --pod-network-cidr=${POD_SUBNET} |& tee kubeadm.log
elif [ ${HA_MASTER} == "y" ]; then
  sudo kubeadm init --control-plane-endpoint "${LOAD_BALANCER_DNS}:${LOAD_BALANCER_PORT}" --upload-certs --pod-network-cidr=${POD_SUBNET} |& tee kubeadm.log
else
  echo "You chose an invalid option for HA control plane. Exiting..."
  exit 1
fi

# kubeconfig setup
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

### Install Calico CNI ########################################################################################
echo
echo Downloading the Tigera Calico operator...
# Function to download the manifest in a loop till successful
calico-dl "https://raw.githubusercontent.com/projectcalico/calico/v3.26.3/manifests/tigera-operator.yaml"

echo
echo Installing the Tigera Calico operator...
sleep 1
kubectl create -f tigera-operator.yaml

echo
echo Downloading Calico...
# Function to download the manifest in a loop till successful
calico-dl "https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml"

# Before creating this manifest, read its contents and make sure its settings are correct for your environment. 
# For example, you may need to change the default IP pool CIDR to match your pod network CIDR.
sed -i "s|cidr: 192.168.0.0/16|cidr: ${POD_SUBNET}|g" custom-resources.yaml

echo
echo Installing Calico...
sleep 1
kubectl create -f custom-resources.yaml
### End Install Calico CNI ########################################################################################

echo
echo Installing Bash completion...
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo chmod a+r /etc/bash_completion.d/kubectl
echo 'alias k=kubectl' >>~/.bashrc
echo 'complete -o default -F __start_kubectl k' >>~/.bashrc
source ~/.bashrc

# Display the join command for the worker nodes
tail -4 kubeadm.log
echo The installation log has been saved as kubeadm.log in the current directory.
exit 0
