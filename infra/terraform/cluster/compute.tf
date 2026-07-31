data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Always-Free eligible Ubuntu ARM image, picked automatically rather than
# hardcoding an OCID that will eventually go stale.
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# First node: k3s server (control plane + workload capacity, since we're
# resource constrained on the free tier). Additional nodes join as agents.
resource "oci_core_instance" "k3s_node" {
  count               = var.node_count
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "k3s-${count.index == 0 ? "server" : "agent-${count.index}"}"
  shape                = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = var.node_ocpus / var.node_count
    memory_in_gbs = var.node_memory_gb / var.node_count
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public.id
    assign_public_ip = true
    display_name     = "k3s-${count.index}-vnic"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_arm.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    # First node bootstraps the cluster; later nodes need the server's
    # private IP + join token, which Terraform doesn't know until the
    # first node exists. See outputs.tf + README for the two-step join
    # process on multi-node setups.
    user_data = count.index == 0 ? base64encode(templatefile("${path.module}/cloud-init-server.yaml", {})) : base64encode(templatefile("${path.module}/cloud-init-agent-placeholder.yaml", {}))
  }

  freeform_tags = {
    environment = var.environment
    project     = "mega-devops"
  }
}
