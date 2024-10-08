variable "er_map_be" {
  type = list(object({
    name          = string
    edgeRouterKey = string
    dnsSvcIpRange = string
    zone          = string
    publicSubnet  = string
  }))
}

variable "region" {
  default = "us-east-2"
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
    us-east-2 = "ami-0d416b2fad9018104"
    us-west-2 = "ami-0d85e528260797f0e"
  }
}

variable "github_pt" {
  default = "test-secret"
}

variable "ssh_public_key" {}

variable "ssh_key_name" {
  default = "be-test-ssh-key"
}

variable "test_initital_delay" {
  default = 600
}

variable "test_iterate_count" {
  default = 200
}

variable "s3_bucket_key" {
  default = "."
}