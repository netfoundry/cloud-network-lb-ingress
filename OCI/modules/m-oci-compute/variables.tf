variable "region" {}
variable "compartment_ocid" {}
variable "er_ssh_public_key" {}
variable "instance_name_prefix" {
  default = "nf-be-er"
}
# Defines the number of instances to deploy
variable "num_instances" {
  default = 2
}
variable "instance_shape" {
  default = "VM.Standard.E4.Flex"
}
variable "instance_ocpus" {
  default = 4
}
variable "instance_shape_config_memory_in_gbs" {
  default = 8
}
variable "vcn_name" {}
variable "route_table_name" {}
variable "subnet_cidr" {}
variable "freeform_tag" {
  default = "terraform_nlb"
}
variable "er_reg_keys" {
  type = list(string)
  validation {
    condition     = length(var.er_reg_keys) == 2
    error_message = "The edge router registration keys were not provided, count of valid keys should be 2"
  }
  default = ["",""]
}
variable "dns_svc_ip_range" {
  default = ["",""]
}
variable "tunnel_ip" {
  default = ""
}