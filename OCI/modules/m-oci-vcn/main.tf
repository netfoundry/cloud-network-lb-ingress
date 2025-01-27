resource "oci_core_vcn" "vcn1" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = var.vcn_name
  dns_label      = replace(var.vcn_name, "_", "")
  freeform_tags = {
		"creator" = var.freeform_tag
	}
}

resource "oci_core_subnet" "nf_subnet" {
  cidr_block          = var.subnet_cidr
  display_name        = "${var.vcn_name}_nfsn"
  dns_label           = replace(var.vcn_name, "_", "")
  compartment_id      = var.compartment_ocid
  vcn_id              = oci_core_vcn.vcn1.id
  freeform_tags = {
    "creator" = var.freeform_tag
  }
  provisioner "local-exec" {
    command = "sleep 5"
  }
}

resource "oci_core_internet_gateway" "internetgateway1" {
  compartment_id = var.compartment_ocid
  display_name   = "${var.vcn_name}-igw01"
  vcn_id         = oci_core_vcn.vcn1.id
  freeform_tags = {
		"creator" = var.freeform_tag
	}
}

resource "oci_core_security_list" "securitylist1" {
  display_name   = "${var.vcn_name}_sl1"
  compartment_id = oci_core_vcn.vcn1.compartment_id
  vcn_id         = oci_core_vcn.vcn1.id
  freeform_tags = {
		"creator" = var.freeform_tag
	}

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }
}

output "vcn_id" {
  value = oci_core_vcn.vcn1.id
}
