output "infra_server_public_ip" {
  description = "Public IP of the infra server - SSH here to do everything else"
  value       = oci_core_instance.infra_server.public_ip
}

output "ssh_command" {
  description = "Run this to connect to your infra server"
  value       = "ssh ubuntu@${oci_core_instance.infra_server.public_ip}"
}
