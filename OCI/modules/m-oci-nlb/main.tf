data "oci_identity_availability_domain" "ad1" {
  compartment_id = var.compartment_ocid
  ad_number      = 1
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
