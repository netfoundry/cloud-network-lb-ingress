data "google_compute_image" "nf_image" {
  project = "netfoundry-marketplace-public"
  filter = "name:nf-ub-2*"
  most_recent = true
}

data "google_compute_subnetwork" "nf_subnetwork" {
  project      = var.project
  name         = var.nf_subnet_name
  region       = var.region
}

resource "google_compute_instance" "backend_edge_router" {
  project      = var.project
  count        = length(var.zone_list)
  name         = "${var.instance_name_prefix}-${var.region}-${count.index}"
  machine_type = var.instance_shape 
  zone         = "${var.region}-${var.zone_list[count.index]}"

  tags = ["nf-fw-rules"]

  boot_disk {
    initialize_params {
      image = "netfoundry-marketplace-public/${data.google_compute_image.nf_image.name}"
    }
  }

  can_ip_forward = true

  network_interface {
      subnetwork = data.google_compute_subnetwork.nf_subnetwork.self_link
      access_config { /* No nat_ip opion provided for Ephemeral public IP*/ }
  }

  metadata = {
      "ssh-keys" = "ziggy:${file(var.er_ssh_public_key)}",
      "user-data" = local.user_data[count.index],
  }
}

output "instance_public_ips" {
  value = google_compute_instance.backend_edge_router.*.network_interface.0.access_config.0.nat_ip
}

output "instance_private_ips" {
  value = google_compute_instance.backend_edge_router.*.network_interface.0.network_ip
}