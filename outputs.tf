output "droplet_ip" {
  description = "Public IPv4 address of the K3s node"
  value       = digitalocean_droplet.k3s.ipv4_address
}

output "ssh_command" {
  description = "SSH command to connect as your admin user"
  value       = "ssh ${var.user_name}@${digitalocean_droplet.k3s.ipv4_address}"
}

output "kube_api_endpoint" {
  description = "Kubernetes API URL (reachable only from admin_cidrs)"
  value       = "https://${digitalocean_droplet.k3s.ipv4_address}:6443"
}
