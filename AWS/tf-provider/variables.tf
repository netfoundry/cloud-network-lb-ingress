variable "er_reg_keys" {
  type = list(string)
  validation {
    condition     = length(var.er_reg_keys) == 2
    error_message = "The edge router registration keys were not provided, count of valid keys should be 2"
  }
}
variable "zone_list" {
    type = list(string)
}
variable "instance_name_prefix" {
  default = "nf-be-er"
}
variable "lb_name_prefix" {
  default = "nf-lb"
}