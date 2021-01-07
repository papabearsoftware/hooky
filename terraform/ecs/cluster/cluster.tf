resource "aws_ecs_capacity_provider" "hooky" {
  name = "hooky-asg"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.hooky.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 90
    }
  }

  depends_on = [
    aws_autoscaling_group.hooky
  ]
}

resource "aws_ecs_cluster" "hooky" {
  name               = var.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.hooky.name]

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "disabled"
  }
  tags = {
    Application = "hooky"
  }

  depends_on = [
    aws_ecs_capacity_provider.hooky
  ]
}