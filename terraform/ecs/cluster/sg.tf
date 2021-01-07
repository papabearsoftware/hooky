resource "aws_security_group" "hooky" {
  name        = "hooky-container-instances"
  description = "SG for Hooky cluster EC2 instances"
  vpc_id      = var.vpc_id
  tags = {
    Application = "hooky"
  }
}

resource "aws_security_group_rule" "hooky_alb_ingress" {
  type                     = "ingress"
  description              = "Allow traffic to 5000 from ALB"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.hooky.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "hooky_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.hooky.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "alb" {
  name        = "hooky-alb"
  description = "Hooky ALB"
  vpc_id      = var.vpc_id
  tags = {
    Application = "hooky"
  }
}

resource "aws_security_group_rule" "alb_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}


resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}