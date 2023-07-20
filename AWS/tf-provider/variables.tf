variable "er_map" {
  type = list(object({
    edgeRouterKey = string
    dnsSvcIpRange = string
    zone          = string
  }))
}
variable "instance_be_prefix" {
  default = "nf-be-er"
}
variable "instance_client_prefix" {
  default = "test_client"
}
variable "lb_name_prefix" {
  default = "nf-lb"
}

variable "include_route_resolver" {
  default = false
}