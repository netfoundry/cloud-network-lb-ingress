data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.compartment_ocid
  ad_number      = 1
}

data "oci_core_internet_gateways" "internet_gateways" {
  compartment_id  = var.compartment_ocid
  display_name    = "${var.vcn_name}-igw01"
  vcn_id          = var.vcn_id
}


resource "oci_network_load_balancer_network_load_balancer" "nlb1" {
  compartment_id = var.compartment_ocid
  subnet_id = var.subnet_id
  display_name = "${var.lb_name_prefix}-${var.region}"
  freeform_tags = {
		"creator" = var.freeform_tag
	}
  is_preserve_source_destination = true
  is_private = true
  nlb_ip_version = "IPV4"
  network_security_group_ids  = [var.er_sg1_id]
}

resource "oci_network_load_balancer_backend_set" "nlb-bes1" {
  name = "${var.lb_name_prefix}-${var.region}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb1.id
  policy = var.backend_set_policy
  health_checker {
    protocol = "HTTPS"
    interval_in_millis = var.backend_set_health_checker_interval_in_millis
    port = 8081
    retries = var.backend_set_health_checker_retries
    return_code = 200
    timeout_in_millis = var.backend_set_health_checker_timeout_in_millis
    url_path = "/health-checks"
  }
  ip_version = "IPV4"
  is_preserve_source = true
}

resource "oci_network_load_balancer_listener" "nlb-listener1" {
  default_backend_set_name = oci_network_load_balancer_backend_set.nlb-bes1.name
  name = "${var.lb_name_prefix}-${var.region}-nlblr1"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb1.id
  port = 0
  protocol = "ANY"
  ip_version = "IPV4"
}

resource "oci_network_load_balancer_backend" "nlb-beadd" {
  count = length(var.instance_ids)
  backend_set_name = oci_network_load_balancer_backend_set.nlb-bes1.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.nlb1.id
  port = 0
  is_backup = var.backend_is_backup
  is_drain = var.backend_is_drain
  is_offline = var.backend_is_offline
  target_id = var.instance_ids[count.index]
  weight = var.backend_weight
}

data "oci_core_route_tables" "routetable1" {
  compartment_id = var.compartment_ocid
  display_name   = var.route_table_name
}

data "oci_core_private_ips" "be_private_ips" {
  count          = length(oci_network_load_balancer_backend.nlb-beadd)
  ip_address     = oci_network_load_balancer_backend.nlb-beadd[count.index].ip_address 
  subnet_id      = var.subnet_id
}

data "oci_core_private_ips" "nlb_private_ips" {
  ip_address     = oci_network_load_balancer_network_load_balancer.nlb1.ip_addresses[0].ip_address
  subnet_id      = var.subnet_id
}

resource "oci_core_default_route_table" "routetable1" {
  compartment_id             = var.compartment_ocid
  manage_default_resource_id = var.vcn_default_route_table_id
  freeform_tags = {
		"creator" = var.freeform_tag
	}
  route_rules {
    destination       = var.dns_svc_ip_range[0]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.be_private_ips[0].private_ips[0].id
  }
  route_rules {
    destination       = var.dns_svc_ip_range[1]
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.be_private_ips[1].private_ips[0].id
  }
  route_rules {
    destination       = "100.127.255.254/32"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.nlb_private_ips.private_ips[0].id
  }
  route_rules {
    destination       = var.peerAddressPrefix
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.nlb_private_ips.private_ips[0].id
  }
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_internet_gateways.internet_gateways.gateways[0].id
  }
}