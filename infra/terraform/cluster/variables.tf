variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy (Profile -> Tenancy in console)"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the user Terraform authenticates as"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API signing key uploaded to your OCI user"
  type        = string
}

variable "private_key_path" {
  description = "Local path to the API signing private key (.pem)"
  type        = string
}

variable "region" {
  description = "OCI region, e.g. us-ashburn-1"
  type        = string
  default     = "ap-hyderabad-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to create resources in"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your local SSH public key, injected into the VM"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the local SSH private key matching ssh_public_key_path, used by Terraform's remote-exec provisioner to patch k3s's TLS SANs after boot"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "node_count" {
  description = "Number of k3s nodes. 1 = single all-in-one node. 2 = server + agent, still within Always Free limits (4 OCPU / 24GB total, split across nodes)."
  type        = number
  default     = 1
}

variable "node_shape" {
  description = "Compute shape for k3s nodes."
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_ocpus" {
  description = "OCPUs per node (Ampere A1 Flex). Always Free cap is 4 total across all A1 instances."
  type        = number
  default     = 4
}

variable "node_memory_gb" {
  description = "Memory per node in GB. Always Free cap is 24GB total across all A1 instances."
  type        = number
  default     = 24
}

variable "environment" {
  description = "Environment tag, e.g. dev or prod. Kept even for a solo project so the pattern is visible."
  type        = string
  default     = "dev"
}
