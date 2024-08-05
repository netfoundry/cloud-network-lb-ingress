// More AWS Modules can be foun here
// https://registry.terraform.io/search/modules?namespace=terraform-aws-modules

module "vpc1" {
    source = "terraform-aws-modules/vpc/aws"

    name = "${var.lb_name_prefix}-vpc"
    cidr = "10.40.0.0/16"

    azs             = toset([for er in var.er_map_be: "${var.region}${er.zone}"])
    //private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets  = toset([for er in var.er_map_be: er.publicSubnet])

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

module "sg_be" {
    source = "terraform-aws-modules/security-group/aws"

    name        = "${var.instance_be_prefix}-sg"
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
            cidr_blocks = "10.0.0.0/8"
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

module "sg_client" {
    source = "terraform-aws-modules/security-group/aws"

    name        = "${var.instance_client_prefix}-sg"
    description = "Security group for clients with custom ports open within VPC"
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
            cidr_blocks = "10.0.0.0/8"
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

data "template_cloudinit_config" "config-be" {
    count = length(local.user_data_be)
    gzip          = true
    base64_encode = true
    part {
        content      = local.user_data_be[count.index]
        content_type = "text/cloud-config"
    }
}

data "template_cloudinit_config" "config-client" {
    count = length(local.user_data_client)
    gzip          = true
    base64_encode = true
    part {
        content      = local.user_data_client[count.index]
        content_type = "text/cloud-config"
    }
}

resource "aws_secretsmanager_secret" "zfw_secret_pt" {
    name                    = var.aws_secret_name
    recovery_window_in_days = 0
    #checkov:skip=CVK2_AWS_57: Disable Secrets Manager secrets automatic rotation
}

resource "aws_secretsmanager_secret_version" "zfw_secret_pt" {
    secret_id     = aws_secretsmanager_secret.zfw_secret_pt.id
    secret_string = var.github_pt
}

resource "aws_iam_policy" "secret_manager_zfw_policy" {
    name        = "glb_test_zfw_secret_read_policy_${var.region}"
    path        = "/"
    description = "Policy to read secret stored in AWS Secrets Store"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow",
                Action = [
                    "secretsmanager:GetSecretValue",
                ]
                Resource = [
                    aws_secretsmanager_secret_version.zfw_secret_pt.arn
                ]
            },
        ]
    })
}

resource "aws_iam_role" "secret_manager_zfw_ec2_role" {
    name = "glb_test_zfw_ec2_role_${var.region}"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid    = ""
                Principal = {
                    Service = "ec2.amazonaws.com"
                }

            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "secret_manager_zfw_policy_attachment" {
    role = aws_iam_role.secret_manager_zfw_ec2_role.name
    policy_arn = aws_iam_policy.secret_manager_zfw_policy.arn
}

resource "aws_iam_instance_profile" "secret_manager_zfw_ec2_profile" {
    role = aws_iam_role.secret_manager_zfw_ec2_role.name
    name = "glb_test_zfw_ec2_profile_${var.region}"
}

module "compute_backend" {
    source  = "terraform-aws-modules/ec2-instance/aws"
    version = "~> 3.0"

    count = length(var.er_map_be)

    name = "${var.instance_be_prefix}-${var.region}${var.er_map_be[count.index].zone}"
    availability_zone = "${var.region}${var.er_map_be[count.index].zone}"
    associate_public_ip_address = true

    ami                      = var.ami_id[var.region]
    instance_type            = "t3.medium"
    key_name                 = "dariuszKey"
    monitoring               = true
    vpc_security_group_ids   = [module.sg_be.security_group_id]
    subnet_id                = module.vpc1.public_subnets[count.index]
    source_dest_check        = false
    iam_instance_profile     = aws_iam_instance_profile.secret_manager_zfw_ec2_profile.name
    user_data_base64         = data.template_cloudinit_config.config-be[count.index].rendered

    tags = {
        Terraform   = "true"
        Environment = "dariusz"
    }
    create = true
}

module "compute_client" {
    source  = "terraform-aws-modules/ec2-instance/aws"
    version = "~> 3.0"

    count = length(var.er_map_be)

    name = "${var.instance_client_prefix}-${var.region}${var.er_map_be[count.index].zone}"
    availability_zone = "${var.region}${var.er_map_be[count.index].zone}"
    associate_public_ip_address = true

    ami                    = var.ami_id[var.region]
    instance_type          = "t3.medium"
    key_name               = "dariuszKey"
    monitoring             = true
    vpc_security_group_ids = [module.sg_client.security_group_id]
    subnet_id              = module.vpc1.public_subnets[count.index]
    source_dest_check      = false
    user_data_base64       = data.template_cloudinit_config.config-client[count.index].rendered


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
    er_list = module.compute_backend.*.id
}

resource "aws_route" "be_resolver_routes" {
    count                   = length(module.compute_backend.*.id)
    route_table_id          = module.vpc1.public_route_table_ids[0]
    destination_cidr_block  = var.er_map_be[count.index].dnsSvcIpRange
    network_interface_id    = module.compute_backend[count.index].primary_network_interface_id
}

output "backend_public_ips" { value = module.compute_backend.*.public_ip}
output "client_public_ips" { value = module.compute_client.*.public_ip}
output "subnets" { value = module.vpc1.public_subnets }
output "route_table_ids" {value = module.vpc1.public_route_table_ids}
output "endpoint_ids" { value = module.gwlb1.endpoint_ids }
