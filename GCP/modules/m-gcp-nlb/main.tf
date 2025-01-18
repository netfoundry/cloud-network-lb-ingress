# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN INTERNAL LOAD BALANCER
# This module deploys an Internal TCP/UDP Load Balancer
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#
# Search for created instances, only on per zone supported
# 
data "google_compute_instance" "backend_edge_router" {
    project      = var.project
    count        = length(var.zone_list)
    name         = "${var.instance_name_prefix}-${var.region}-${count.index}"
    zone         = "${var.region}-${var.zone_list[count.index]}"
}

# ------------------------------------------------------------------------------
# CREATE Instance Group
# ------------------------------------------------------------------------------
resource "google_compute_instance_group" "backend_edge_router-group" {
  project   = var.project
  count     = length(data.google_compute_instance.backend_edge_router)
  name      = "${var.instance_name_prefix}-${var.region}"
  zone      = "${var.region}-${var.zone_list[count.index]}"
  instances = [element(data.google_compute_instance.backend_edge_router.*.id, count.index)]
}

# ------------------------------------------------------------------------------
# CREATE HEALTH CHECK ´https'´
# ------------------------------------------------------------------------------

resource "google_compute_health_check" "backend_edge_router-hc" {
  project             = var.project
  name                = "${var.instance_name_prefix}-${var.region}-hc"
  https_health_check {
    port          = "8081"
    request_path  = "/health-checks"
  }
  check_interval_sec  = 5
  healthy_threshold   = 3
  unhealthy_threshold = 3
  timeout_sec         = 5
}

# ------------------------------------------------------------------------------
# CREATE BACKEND SERVICE TCP
# ------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "nlb-beadd-tcp" {
  project                         = var.project
  name                            = "${var.lb_name_prefix}-${var.region}-tcp"
  region                          = var.region
  health_checks                   = [google_compute_health_check.backend_edge_router-hc.id]
  connection_draining_timeout_sec = 300
  session_affinity                = var.session_affinity
  protocol                        = "TCP"
  backend {
    group = google_compute_instance_group.backend_edge_router-group[0].self_link
  }
  backend {
    group = google_compute_instance_group.backend_edge_router-group[1].self_link
  }
}

# ------------------------------------------------------------------------------
# CREATE BACKEND SERVICE UDP
# ------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "nlb-beadd-udp" {
  project             = var.project
  name                = "${var.lb_name_prefix}-${var.region}-udp"
  region              = var.region
  health_checks       = [google_compute_health_check.backend_edge_router-hc.id]
  session_affinity    = var.session_affinity
  protocol            = "UDP"
  backend {
    group = google_compute_instance_group.backend_edge_router-group[0].self_link
  }
  backend {
    group = google_compute_instance_group.backend_edge_router-group[1].self_link
  }
}

# ------------------------------------------------------------------------------
# CREATE FORWARDING RULE TCP
# ------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "nlb-fw-rl-tcp" {
  project               = var.project
  name                  = "${var.lb_name_prefix}-${var.region}-fw-rl-tcp"
  region                = var.region
  subnetwork            = var.nf_subnet_name
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.nlb-beadd-tcp.id
  ip_protocol           = "TCP"
  all_ports             = true
}

# ------------------------------------------------------------------------------
# CREATE FORWARDING RULE UDP
# ------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "nlb-fwd-rl-udp" {
  project               = var.project
  name                  = "${var.lb_name_prefix}-${var.region}-fwd-rl-udp"
  region                = var.region
  subnetwork            = var.nf_subnet_name
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.nlb-beadd-udp.id
  ip_protocol           = "UDP"
  all_ports             = true
}

resource "google_compute_route" "route-ilb-tcp" {
  project      = var.project
  name         = "route-ilb-tcp"
  dest_range   = var.dest_cidr_list[0]
  network      = var.vcn_name
  next_hop_ilb = google_compute_forwarding_rule.nlb-fw-rl-tcp.id
  priority     = 2000
}

resource "google_compute_route" "route-ilb-udp" {
  project      = var.project
  name         = "route-ilb-udp"
  dest_range   = var.dest_cidr_list[0]
  network      = var.vcn_name
  next_hop_ilb = google_compute_forwarding_rule.nlb-fwd-rl-udp.id
  priority     = 2000
}

resource "google_compute_route" "route-dns-reslv-tcp" {
  project      = var.project
  name         = "route-dns-reslv-tcp"
  dest_range   = "100.127.255.254/32"
  network      = var.vcn_name
  next_hop_ilb = google_compute_forwarding_rule.nlb-fw-rl-tcp.id
  priority     = 2000
}

resource "google_compute_route" "route-dns-reslv-udp" {
  project      = var.project
  name         = "route-dns-reslv-udp"
  dest_range   = "100.127.255.254/32"
  network      = var.vcn_name
  next_hop_ilb = google_compute_forwarding_rule.nlb-fwd-rl-udp.id
  priority     = 2000
}

resource "google_compute_route" "route-dnssvciprange" {
  project      = var.project
  count        = length(var.zone_list)
  name         = "route-dnssvcip${count.index}"
  dest_range   = var.dns_svc_ip_range[count.index]
  network      = var.vcn_name
  next_hop_ip  = data.google_compute_instance.backend_edge_router[count.index].network_interface.0.network_ip
  priority     = 2000
}
