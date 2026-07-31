# A small, separate VCN from the cluster's own network. The infra server
# doesn't need to share a network with k3s - it reaches the cluster's
# API server (port 6443) and Ingress (80/443) over their already-public
# IPs, the same way your laptop would. Keeping it separate also means
# tearing down or rebuilding the cluster never touches this box.

resource "oci_core_vcn" "infra" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.1.0.0/16"]
  display_name   = "infra-server-vcn"
  dns_label      = "infraserver"
}

resource "oci_core_internet_gateway" "infra" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.infra.id
  display_name   = "infra-server-igw"
  enabled        = true
}

resource "oci_core_route_table" "infra" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.infra.id
  display_name   = "infra-server-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.infra.id
  }
}

# Only SSH inbound - this box doesn't host anything itself, it's a
# control/jump machine. Everything it does to the cluster goes out over
# egress to the cluster's own public endpoints.
resource "oci_core_security_list" "infra" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.infra.id
  display_name   = "infra-server-sl"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "infra" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.infra.id
  cidr_block                 = "10.1.1.0/24"
  display_name               = "infra-server-subnet"
  dns_label                  = "infra"
  route_table_id             = oci_core_route_table.infra.id
  security_list_ids          = [oci_core_security_list.infra.id]
  prohibit_public_ip_on_vnic = false
}
