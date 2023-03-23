resource "aws_lb" "glb" {
  load_balancer_type = "gateway"
  name               = "${var.lb_name_prefix}-01"
  
  dynamic "subnet_mapping" {
    for_each = toset(var.subnets)
    content {
      subnet_id = subnet_mapping.value
    }
  }

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true
}

resource "aws_lb_target_group" "glb_tg" {
  name     = "${var.lb_name_prefix}-tg"
  port     = 6081
  protocol = "GENEVE"
  target_type = "instance"
  vpc_id   = var.vpc_id

  health_check {
    enabled           = true
    port              = 8081
    protocol          = "HTTPS"
    path              = "/health-checks"
    healthy_threshold = 3
    unhealthy_threshold = 3
    interval          = 10
    timeout           = 5
    matcher           = "200-399"
  }
}

resource "aws_lb_target_group_attachment" "glb_tg_attach" {
  count = length(var.er_list)
  target_group_arn = aws_lb_target_group.glb_tg.arn
  target_id        = var.er_list[count.index]
}

resource "aws_lb_listener" "glb_fe" {
  load_balancer_arn = aws_lb.glb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.glb_tg.arn
    
  }
}

resource "aws_vpc_endpoint_service" "glb_es" {
  acceptance_required        = false
  allowed_principals         = ["arn:aws:iam::aws-account-id:user/*"]
  gateway_load_balancer_arns = [aws_lb.glb.arn]
}

resource "aws_vpc_endpoint" "ep" {
  count = length(var.subnets)
  service_name       = aws_vpc_endpoint_service.glb_es.service_name
  subnet_ids         = [var.subnets[count.index]]
  vpc_endpoint_type  = aws_vpc_endpoint_service.glb_es.service_type
  vpc_id             = var.vpc_id
}

resource "aws_route" "glb_routes" {
  count = length(aws_vpc_endpoint.ep.*.id)
  route_table_id            = local.route_table_list[count.index]
  destination_cidr_block    = "10.10.20.0/24"
  vpc_endpoint_id           = aws_vpc_endpoint.ep[count.index].id
}

output "endpoint_ids" {
  value = aws_vpc_endpoint.ep.*.id
}