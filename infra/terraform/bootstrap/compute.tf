data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# VM.Standard.E2.1.Micro is a FIXED shape (not Flex) - unlike the A1
# Flex instances used for the k3s cluster, you don't specify ocpus/memory
# here; the shape itself is fixed at 1/8 OCPU and 1GB RAM. Oracle's
# Always Free tier includes up to 2 of these, entirely separate from the
# 4 OCPU / 24GB Ampere A1 allowance the cluster uses - so this costs
# nothing extra and doesn't compete with the cluster for your free quota.
data "oci_core_images" "ubuntu_amd64" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "infra_server" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "infra-server"
  shape                = "VM.Standard.E2.1.Micro"

  create_vnic_details {
    subnet_id        = oci_core_subnet.infra.id
    assign_public_ip = true
    display_name     = "infra-server-vnic"
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu_amd64.images[0].id
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.module}/cloud-init-infra-server.yaml"))
  }

  freeform_tags = {
    project = "mega-devops"
    role    = "infra-server"
  }
}
