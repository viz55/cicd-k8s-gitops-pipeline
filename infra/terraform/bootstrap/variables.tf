variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
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
  default     = "us-ashburn-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment to create resources in"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path to your local SSH public key, injected into the infra server"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
