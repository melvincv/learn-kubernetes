# Create kubernetes Droplets
resource "digitalocean_droplet" "k8s-master" {
  image  = "ubuntu-20-04-x64"
  name   = "kube-master"
  region = "sgp1"
  size   = "s-2vcpu-2gb"
  ssh_keys = ["39828591", "39828597"]
  tags = ["k8s"]
}

resource "digitalocean_droplet" "k8s-nodes" {
  image  = "ubuntu-20-04-x64"
  name   = "${var.name_prefix}-${count.index + 1}"
  region = "sgp1"
  size   = "s-2vcpu-4gb"
  ssh_keys = ["39828591", "39828597"]
  tags = ["k8s-node"]
  count = 2
}
