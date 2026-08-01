# k3s only signs its API server cert for the IPs it knows about at install
# time (private IP, cluster IPs, localhost) — never the node's public IP,
# since that's assigned by OCI *after* the instance boots and cloud-init
# has already run. Left alone, kubectl from the infra server (or anywhere
# off-box) fails TLS verification against the public IP.
#
# This waits for k3s to come up, then adds --tls-san for the server node's
# actual public IP and forces k3s to regenerate its cert. It reruns
# automatically whenever the server node is replaced (new public IP),
# so `terraform destroy && terraform apply` never needs a manual patch.
resource "null_resource" "k3s_tls_san_fix" {
  triggers = {
    instance_id = oci_core_instance.k3s_node[0].id
    public_ip   = oci_core_instance.k3s_node[0].public_ip
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = oci_core_instance.k3s_node[0].public_ip
    private_key = file(var.ssh_private_key_path)
    timeout     = "5m"
  }

  provisioner "remote-exec" {
    inline = [
      # cloud-init's k3s install can still be running when SSH first opens
      "timeout 300 bash -c 'until systemctl is-active --quiet k3s; do sleep 5; done'",

      # k3s reads /etc/rancher/k3s/config.yaml on start for options like this
      # (safer than editing the systemd unit, whose ExecStart= k3s writes as
      # a multi-line, backslash-continued value that a naive sed will break).
      # Idempotent: skip if this public IP is already in the file.
      "if [ ! -f /etc/rancher/k3s/config.yaml ] || ! grep -q '${oci_core_instance.k3s_node[0].public_ip}' /etc/rancher/k3s/config.yaml; then printf 'tls-san:\\n  - %s\\n' '${oci_core_instance.k3s_node[0].public_ip}' | sudo tee -a /etc/rancher/k3s/config.yaml >/dev/null && sudo rm -f /var/lib/rancher/k3s/server/tls/dynamic-cert.json && sudo systemctl restart k3s; fi",

      # Wait for the API server to actually be back up before Terraform hands control back
      "timeout 120 bash -c 'until sudo test -f /etc/rancher/k3s/k3s.yaml; do sleep 3; done'",
      "timeout 120 bash -c 'until sudo k3s kubectl get nodes >/dev/null 2>&1; do sleep 5; done'",
    ]
  }
}

