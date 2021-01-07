// TODO add tags
resource "aws_launch_template" "workers" {
  name                   = "hooky-ecs-cluster"
  update_default_version = true
  image_id               = data.aws_ssm_parameter.ecs_ami_id.value
  instance_type          = "t3a.medium" // TODO turn into var
  // TODO it's probably best to create a separate SG for the instances and have containers use a more specific SG (if using awsvpc network mode for service)
  key_name = var.ssh_key_name
  user_data = base64encode(<<EOF
#!/usr/bin/env bash

echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
echo ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance >> /etc/ecs/ecs.config
EOF
  )

  iam_instance_profile {
    arn = aws_iam_instance_profile.instance_profile.arn
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 40
      delete_on_termination = true
      volume_type           = "gp2"
    }
  }

  network_interfaces {
    associate_public_ip_address = var.assign_public_ip
    security_groups             = [aws_security_group.hooky.id]
    delete_on_termination       = true
  }

  cpu_options {
    core_count       = 1 // TODO turn into var
    threads_per_core = 2 // TODO turn into var
  }

}

resource "aws_autoscaling_group" "hooky" {
  name                      = "hooky-asg"
  max_size                  = 3
  min_size                  = 3
  desired_capacity          = 3
  health_check_grace_period = 300
  health_check_type         = "EC2"
  vpc_zone_identifier       = var.asg_subnets
  termination_policies      = ["OldestLaunchTemplate", "ClosestToNextInstanceHour", "Default"]
  max_instance_lifetime     = 604800 // One week

  tags = [
    {
      "key"                 = "Application"
      "value"               = "hooky"
      "propagate_at_launch" = true
    },
    {
      "key"                 = "AmazonECSManaged"
      "value"               = ""
      "propagate_at_launch" = true
    },
    {
      "key"                 = "Name"
      "value"               = var.cluster_name
      "propagate_at_launch" = true
    }
  ]

  instance_refresh {
    strategy = "Rolling"
  }

  launch_template {
    name    = aws_launch_template.hooky.name
    version = "$Latest"
  }

  // Must be true if ECS will manage autoscaling
  protect_from_scale_in = true

  depends_on = [
    aws_launch_template.hooky
  ]
}