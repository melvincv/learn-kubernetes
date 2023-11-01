output "k8s-master-ip" {
  value = digitalocean_droplet.k8s-master.ipv4_address
}

output "k8s-node-ips" {
  value = digitalocean_droplet.k8s-nodes[*].ipv4_address
}