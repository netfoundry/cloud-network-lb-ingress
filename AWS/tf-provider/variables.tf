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

variable "repo_name" {
  default = "zfw"
}

variable "ziti_type" {
  default = "zfw-router"
}

variable "custom_ami_id" {
  description = "Custom AMI IDs per region"
  type        = map(string)
  default = {
    us-east-2 = "ami-09517c1d39178d677"
    us-west-2 = "ami-0de211ca151303d4e"
  }
}

variable "use_custom_ami" {
  description = "Use custom AMI instead of marketplace NF ER AMI"
  type        = bool
  default     = false
}