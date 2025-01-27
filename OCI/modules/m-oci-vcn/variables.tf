variable "region" {}
variable "compartment_ocid" {}
variable "vcn_name" {}
variable "vcn_cidr" {}
variable "route_table_name" {}
variable "freeform_tag" {
    default = "terraform_nlb"
}
variable "subnet_cidr" {}
