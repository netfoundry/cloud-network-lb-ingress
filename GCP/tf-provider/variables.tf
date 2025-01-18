variable "vcn_name" {}
variable "region" {}
variable "zone_list" {
    description = "zone list used to deply NF ERs in"
    type        = list
    default     = ["b","c"]
}
variable "nf_subnet_cidr" {}
variable "nf_router_registration_key_list" {}
variable "project" {}
variable "dns_svc_ip_range" {}
