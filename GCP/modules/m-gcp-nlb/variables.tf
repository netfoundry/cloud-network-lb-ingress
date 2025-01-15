variable "region" {}
variable "project" {}
variable "vcn_name" {}
variable "zone_list" {
    description = "zone list used to deply NF ERs in"
    type        = list
    default     = ["b","c"]
}
variable "nf_subnet_name" {
    description = "NetFoundry subnet name"
    type        = string
    default     = "nf-public-subnet"
}
variable "instance_name_prefix" {
  default = "nf-be-er"
}
variable "session_affinity" {
  description = "NONE, CLIENT_IP, CLIENT_IP_PORT_PROTO, CLIENT_IP_PROTO, and CLIENT_IP_NO_DESTINATION"
  default = "CLIENT_IP_PORT_PROTO"
}
variable "lb_name_prefix" {
  default = "nf-lb"
}

variable "dest_cidr_list" {
    description = "Destination Cidr List to forward"
    type        = list
    default     = ["192.168.4.0/22"]
}

