resource "aws_lb" "alb" {
  name                       = "hooky-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.alb_subnets
  ip_address_type            = "ipv4"
  enable_deletion_protection = false // change to true when deploying in prod

  tags = {
    Application = "hooky"
  }
}

resource "aws_lb_target_group" "hooky" {
  name     = "hooky-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  // https://docs.aws.amazon.com/AmazonECS/latest/userguide/create-application-load-balancer.html
  target_type          = "instance" // must be "ip" if using awsvpc network mode for ECS task def
  deregistration_delay = 10

  health_check {
    enabled             = true
    interval            = 120
    path                = "/api/v1/healthcheck"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn
  // Optionally we can set up some aws_lb_listener_rule and turn the default action into something else
  // If we wanted to do name based routing for example
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.hooky.arn
  }
}

