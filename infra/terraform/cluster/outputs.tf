output "node_public_ips" {
  description = "Public IPs of all k3s nodes, in order (index 0 = server)"
  value       = oci_core_instance.k3s_node[*].public_ip
}

output "k3s_server_public_ip" {
  description = "Public IP of the k3s server node"
  value       = oci_core_instance.k3s_node[0].public_ip
}

output "kubeconfig_fetch_command" {
  description = "Run this to pull kubeconfig locally and point it at the node's public IP"
  value       = "ssh ubuntu@${oci_core_instance.k3s_node[0].public_ip} sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/${oci_core_instance.k3s_node[0].public_ip}/' > ~/.kube/config-mega-devops"
}
