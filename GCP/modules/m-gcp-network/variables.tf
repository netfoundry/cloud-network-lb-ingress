
variable "vcn_name" {}
variable "region" {}
variable "nf_subnet_name" {
    description = "NetFoundry subnet name"
    type        = string
    default     = "nf-public-subnet"
}
variable "nf_subnet_cidr" {}
variable "create_vcn" {
    description = "If true creates vcn network, otherwise skip it"
    type        = bool
    default     = false
}
