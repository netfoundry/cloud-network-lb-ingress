// More AWS Modules can be foun here
// https://registry.terraform.io/search/modules?namespace=terraform-aws-modules

module "vpc1" {
    source = "terraform-aws-modules/vpc/aws"

    name = "${var.lb_name_prefix}-vpc"
    cidr = "10.40.0.0/16"

    azs             = var.zone_list
    //private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = ["10.40.101.0/24", "10.40.102.0/24"]

    enable_nat_gateway      = false
    enable_vpn_gateway      = true
    enable_dns_hostnames    = true
    enable_dns_support      = true
    map_public_ip_on_launch = true
    create_igw              = true

    tags = {
        Terraform = "true"
        Environment = "dariusz"
    }

    create_vpc = true
}

module "sg1" {
    source = "terraform-aws-modules/security-group/aws"

    name        = "${var.instance_name_prefix}-sg"
    description = "Security group for backend er of glb with custom ports open within VPC"
    vpc_id      = module.vpc1.vpc_id

    egress_with_cidr_blocks  = [
        {
            rule        = "all-all"
            cidr_blocks = "0.0.0.0/0"
        }  
    ]

    ingress_with_cidr_blocks = [
        {
            rule        = "all-all"
            cidr_blocks = "10.40.0.0/16"
        },
        {
            rule        = "ssh-tcp"
            cidr_blocks = "0.0.0.0/0"
        },
    ]

    tags = {
        Terraform   = "true"
        Environment = "dariusz"
    }
    create = true
}

module "compute1" {
    source  = "terraform-aws-modules/ec2-instance/aws"
    version = "~> 3.0"

    count = length(var.zone_list)

    name = "${var.instance_name_prefix}-${var.zone_list[count.index]}"
    availability_zone = var.zone_list[count.index]
    associate_public_ip_address = true

    ami                    = "ami-0869c5a62c16acd0a"
    instance_type          = "t3.medium"
    key_name               = "dariuszKey"
    monitoring             = true
    vpc_security_group_ids = [module.sg1.security_group_id]
    subnet_id              = module.vpc1.public_subnets[count.index]
    source_dest_check      = false
    user_data              = local.user_data[count.index]

    tags = {
        Terraform   = "true"
        Environment = "dariusz"
    }
    create = true
}

module "gwlb1" {
    source = "../modules/m-aws-glb"

    vpc_id = module.vpc1.vpc_id
    subnets = module.vpc1.public_subnets
    default_rt_id = module.vpc1.default_route_table_id
    public_rt_ids = module.vpc1.public_route_table_ids
    er_list = module.compute1.*.id
}

output "public_ips" { value = module.compute1.*.public_ip}
output "subnets" { value = module.vpc1.public_subnets }
output "route_table_ids" {value = module.vpc1.public_route_table_ids}
output "endpoint_ids" { value = module.gwlb1.endpoint_ids }
