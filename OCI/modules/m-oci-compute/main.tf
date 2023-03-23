/*
    Resource Elements
*/
resource "oci_marketplace_accepted_agreement" "test_accepted_agreement" {
  agreement_id    = oci_marketplace_listing_package_agreement.test_listing_package_agreement.agreement_id
  compartment_id  = var.compartment_ocid
  listing_id      = data.oci_marketplace_listing.test_listing.id
  package_version = data.oci_marketplace_listing.test_listing.default_package_version
  signature       = oci_marketplace_listing_package_agreement.test_listing_package_agreement.signature
}
resource "oci_marketplace_listing_package_agreement" "test_listing_package_agreement" {
  agreement_id    = data.oci_marketplace_listing_package_agreements.test_listing_package_agreements.agreements[0].id
  listing_id      = data.oci_marketplace_listing.test_listing.id
  package_version = data.oci_marketplace_listing.test_listing.default_package_version
}
/*
    Data Elements
*/
data "oci_marketplace_listing_package_agreements" "test_listing_package_agreements" {
  listing_id      = data.oci_marketplace_listing.test_listing.id
  package_version = data.oci_marketplace_listing.test_listing.default_package_version
  compartment_id = var.compartment_ocid
}
data "oci_marketplace_listing_package" "test_listing_package" {
  listing_id      = data.oci_marketplace_listing.test_listing.id
  package_version = data.oci_marketplace_listing.test_listing.default_package_version
  compartment_id = var.compartment_ocid
}
data "oci_marketplace_listing_packages" "test_listing_packages" {
  listing_id = data.oci_marketplace_listing.test_listing.id
  compartment_id = var.compartment_ocid
}
data "oci_marketplace_listing" "test_listing" {
  listing_id     = data.oci_marketplace_listings.test_listings.listings[0].id
  compartment_id = var.compartment_ocid
}
data "oci_marketplace_listings" "test_listings" {
#  category       = ["security"]
  name = ["NetFoundry Edge Router"]
  compartment_id = var.compartment_ocid
}
data "oci_core_app_catalog_listing_resource_version" "test_catalog_listing" {
  listing_id = data.oci_marketplace_listing_package.test_listing_package.app_catalog_listing_id
  resource_version = data.oci_marketplace_listing_package.test_listing_package.app_catalog_listing_resource_version
}
/*
Lookup vcn id and route table id
*/
data "oci_core_vcns" "lookup_vcn" {
  compartment_id  = var.compartment_ocid
  display_name    = var.vcn_name
}
data "oci_core_route_tables" "lookup_route_table" {
  compartment_id  = var.compartment_ocid
  display_name    = var.route_table_name
  vcn_id          = data.oci_core_vcns.lookup_vcn.virtual_networks[0].id
}
/*
Create nf edge router subnet
*/
resource "oci_core_subnet" "nf_subnet" {
  cidr_block          = var.subnet_cidr
  display_name        = "${var.vcn_name}_nfsn"
  dns_label           = replace(var.vcn_name, "_", "")
  compartment_id      = var.compartment_ocid
  vcn_id              = data.oci_core_vcns.lookup_vcn.virtual_networks[0].id
  route_table_id      = data.oci_core_route_tables.lookup_route_table.route_tables[0].id
  freeform_tags = {
    "creator" = var.freeform_tag
  }
  provisioner "local-exec" {
    command = "sleep 5"
  }
}
/*
Security group for Edge Routers
*/
resource "oci_core_network_security_group" "edge_router_sg1" {
  compartment_id = var.compartment_ocid
  vcn_id = data.oci_core_vcns.lookup_vcn.virtual_networks[0].id
  display_name = "${var.instance_name_prefix}-${var.region}"
  freeform_tags = {
    "creator" = var.freeform_tag
  }
}
resource "oci_core_network_security_group_security_rule" "edge_router_sg1_egress_rule_all" {
    network_security_group_id = oci_core_network_security_group.edge_router_sg1.id
    direction = "EGRESS"
    protocol = "ALL"
    description = "egress rule for all nf edge routers"
    destination = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless = false
}
resource "oci_core_network_security_group_security_rule" "edge_router_sg1_ingress_rule_all_local" {
    network_security_group_id = oci_core_network_security_group.edge_router_sg1.id
    direction = "INGRESS"
    protocol = "ALL"
    description = "ingress rule for all nf edge routers"
    source = var.subnet_cidr
    source_type = "CIDR_BLOCK"
    stateless = false
}
resource "oci_core_network_security_group_security_rule" "edge_router_sg1_ingress_rule_ssh_remote" {
    network_security_group_id = oci_core_network_security_group.edge_router_sg1.id
    direction = "INGRESS"
    protocol = "6"
    description = "ingress rule for all nf edge routers"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless = false
    tcp_options {
      destination_port_range {
          max = 22
          min = 22
      }
    }
}
/*
    Compute Resources
*/
resource "oci_core_instance" "backend_edge_router" {
  count               = var.num_instances
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[count.index].name
  compartment_id      = var.compartment_ocid
  display_name        = "${var.instance_name_prefix}${count.index}"
  shape               = var.instance_shape

  shape_config {
    ocpus = var.instance_ocpus
    memory_in_gbs = var.instance_shape_config_memory_in_gbs
  }

  create_vnic_details {
    subnet_id                 = resource.oci_core_subnet.nf_subnet.id
    display_name              = "${var.instance_name_prefix}${count.index}-vnic"
    assign_public_ip          = true
    assign_private_dns_record = true
    skip_source_dest_check    = true
    nsg_ids                   = [oci_core_network_security_group.edge_router_sg1.id]
    hostname_label            = "${var.instance_name_prefix}${count.index}"
  }

  source_details {
    source_type = "image"
    source_id = data.oci_core_app_catalog_listing_resource_version.test_catalog_listing.listing_resource_id
  }

  metadata = {
    ssh_authorized_keys = file(var.er_ssh_public_key)
    user_data           = base64encode(local.user_data[count.index])
  }

  freeform_tags = {
    "creator" = "${var.freeform_tag}"
  }

  # crate operaiton time out
  timeouts {
    create = "60m"
  }
}

output "instance_private_ips" {
  value = oci_core_instance.backend_edge_router.*.private_ip
}
output "instance_public_ips" {
  value = oci_core_instance.backend_edge_router.*.public_ip
}

output "instance_ids" {
  value = oci_core_instance.backend_edge_router.*.id
}

output "subnet_id" {
  value = oci_core_subnet.nf_subnet.id
}

output "vcn_id" {
  value = data.oci_core_vcns.lookup_vcn.virtual_networks[0].id
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_ocid
}
