variable "region" {}
variable "zone_list" {
    description = "zone list used to deply NF ERs in"
    type        = list
    default     = ["b"]
}
variable "er_ssh_public_key" {}
variable "nf_subnet_name" {
    description = "NetFoundry subnet name"
    type        = string
    default     = "nf-public-subnet"
}
variable "image_name" {
    description = "netfoundry marketplace image"
    type        = string
    default     = "netfoundry-marketplace-public/nf-ub-1-10-20220719"
}
variable "instance_name_prefix" {
  default = "nf-be-er"
}
variable "instance_shape" {
  default = "e2-medium"
}
variable "er_reg_keys" {
  type = list(string)
  validation {
    condition     = length(var.er_reg_keys) == 1
    error_message = "The edge router registration keys were not provided, count of valid keys should be 2"
  }
}
