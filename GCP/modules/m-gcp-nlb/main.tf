# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# DEPLOY AN INTERNAL LOAD BALANCER
# This module deploys an Internal TCP/UDP Load Balancer
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#
# Search for created instances, only on per zone supported
# 
data "google_compute_instance" "nf-edge-routers" {
    count  = length(var.zone_list)
    name   = "${var.instance_name_prefix}-${var.region}-${count.index}"
    zone   = "${var.region}-${var.zone_list[count.index]}"
}

# ------------------------------------------------------------------------------
# CREATE Instance Group
# ------------------------------------------------------------------------------
resource "google_compute_instance_group" "nf-edge-routers-group" {
  count  = length(data.google_compute_instance.nf-edge-routers.*.self_link)
  name   = "${var.instance_name_prefix}-${var.region}-${count.index}"
  zone = "${var.region}-${var.zone_list[count.index]}"
  instances = [try(element(data.google_compute_instance.nf-edge-routers.*.self_link, count.index))]
}

# ------------------------------------------------------------------------------
# CREATE HEALTH CHECK ´https'´
# ------------------------------------------------------------------------------

resource "google_compute_health_check" "nf-edge-routers-hc" {
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
  name                            = "${var.lb_name_prefix}-${var.region}-tcp"
  region                          = var.region
  health_checks                   = [google_compute_health_check.nf-edge-routers-hc.id]
  connection_draining_timeout_sec = 300
  session_affinity                = var.session_affinity
  backend {
    group                         = google_compute_instance_group.nf-edge-routers-group.0.self_link
  }
  backend {
    group                         = google_compute_instance_group.nf-edge-routers-group.1.self_link
  }
  protocol                        = "TCP"
}

# ------------------------------------------------------------------------------
# CREATE BACKEND SERVICE UDP
# ------------------------------------------------------------------------------

resource "google_compute_region_backend_service" "nlb-beadd-udp" {
  name                            = "${var.lb_name_prefix}-${var.region}-udp"
  region                          = var.region
  health_checks                   = [google_compute_health_check.nf-edge-routers-hc.id]
  session_affinity                = var.session_affinity
  backend {
    group                         = google_compute_instance_group.nf-edge-routers-group.0.self_link
  }
  backend {
    group                         = google_compute_instance_group.nf-edge-routers-group.1.self_link
  }
  protocol                        = "UDP"
}

# ------------------------------------------------------------------------------
# CREATE FORWARDING RULE TCP
# ------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "nlb-fw-rl-tcp" {
  name                  = "${var.lb_name_prefix}-${var.region}-fw-rl-tcp"
  region                = var.region
  subnetwork            = var.nf_subnet_name
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.nlb-beadd-tcp.self_link
  ip_protocol           = "TCP"
  all_ports             = true
}

# ------------------------------------------------------------------------------
# CREATE FORWARDING RULE UDP
# ------------------------------------------------------------------------------

resource "google_compute_forwarding_rule" "nlb-fwd-rl-udp" {
  name                  = "${var.lb_name_prefix}-${var.region}-fwd-rl-udp"
  region                = var.region
  subnetwork            = var.nf_subnet_name
  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.nlb-beadd-udp.self_link
  ip_protocol           = "UDP"
  all_ports             = true
}