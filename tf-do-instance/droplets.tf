# Create kubernetes Droplets
resource "digitalocean_droplet" "k8s-controlplanes" {
  image  = var.distro_image
  name   = "${var.cp_name_prefix}-${count.index + 1}"
  region = "sgp1"
  size   = "s-2vcpu-2gb"
  ssh_keys = ["40208387", "39828597"]
  tags = ["k8s"]
  count = 1
}

resource "digitalocean_droplet" "k8s-nodes" {
  image  = var.distro_image
  name   = "${var.name_prefix}-${count.index + 1}"
  region = "sgp1"
  size   = "s-2vcpu-4gb"
  ssh_keys = ["40208387", "39828597"]
  tags = ["k8s-node"]
  count = 1
}
