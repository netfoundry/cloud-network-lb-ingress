variable "er_map_be" {
  type = list(object({
    edgeRouterKey = string
    dnsSvcIpRange = string
    zone          = string
    publicSubnet  = string
  }))
}

variable "region" {
  default = "us-east-2"
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

variable "ami_id" {
  default = {
    us-east-2 = "ami-0b30ef8bf8f331e78"
    us-west-2 = "ami-0333611f8a06d64d0"
  }
}

variable "github_pt" {
  default = "test-secret"
}

variable "aws_secret_name" {
  default = "glb_test_zfw_repo"
}

variable "ssh_public_key" {
  default = "DariuszKey"
}