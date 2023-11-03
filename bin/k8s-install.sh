#!/bin/bash -xe
## Install Kubernetes v1.28 on Ubuntu LTS using kubeadm
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

### Define Variables ###
# User Prompts
read -p "This script will install Kubernetes with Calico on Ubuntu LTS. Press Enter to continue."
read -p "Have you set the correct hostname? [y/n] : " ISHOSTSET

# Function call to set hostname and reboot if needed
sethostname

read -p "Is this the master node? [y/n]: " IS_MASTER
IS_MASTER=${IS_MASTER:-n}
### Define Variables End ###

# Function calls
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
echo Installing kubelet, kubeadm and kubectl...
# In releases older than Debian 12 and Ubuntu 22.04, /etc/apt/keyrings does not exist by default
if [ ! -d /etc/apt/keyrings ]; then
    sudo mkdir -m 755 /etc/apt/keyrings
fi

# Save the existing value of PS3
oPS3=$PS3
# User Prompt
PS3="Choose an option: "
# select loop 
echo "Select your Kubernetes Version: "
select VER in "1.28" "1.27" "1.26" "exit script"
do
  if [ ! -z "$VER" ]; then
    case $REPLY in
      1) installk8s-128; break ;;
      2) installk8s-127; break ;;
      3) installk8s-126; break ;;
      4) exit 0 ;;
    esac
  else
      echo "$REPLY is not a valid option. Choose between 1 to 4"
  fi
done

# Put PS3 back to what it was
PS3=$oPS3

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
