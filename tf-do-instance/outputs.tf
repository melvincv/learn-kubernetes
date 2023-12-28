output "k8s-controlplane-ips" {
  value = digitalocean_droplet.k8s-controlplanes[*].ipv4_address
}

output "k8s-node-ips" {
  value = digitalocean_droplet.k8s-nodes[*].ipv4_address
}