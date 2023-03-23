variable "subnets" {
    type  = list
}
variable "vpc_id" {
    type  = string
}
variable "instance_name_prefix" {
  default = "nf-be-er"
}
variable "lb_name_prefix" {
  default = "nf-lb"
}
variable "default_rt_id" {}
variable "public_rt_ids" {
  type = list
}
variable "er_list" {
  type = list
}