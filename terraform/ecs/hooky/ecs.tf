data "template_file" "api_containers" {
  template = file("api_containers.json.tpl")
  vars = {
    commands                      = var.hooky_container_commands // The template evaluates boolean statements, so we set commands to `false` to use whatever is in the Dockerfile for CMD
    // You can override the command by specifying a new command here
    // If you do that, you must jsonencode() it, e.g. jsonencode(["/path/to/foo", "bar", "-arg", "value"])
    container_image               = "${var.ecr_repo}:${var.container_version}"
    // CPU and memory are bound together
    // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-cpu-memory-error.html
    cpu                           = 512 // .5 vCPU
    memory                        = 1024
    memory_soft_limit             = 1024
    region                        = data.aws_region.current.name
    db_hostname                   = var.db_hostname
    db_user                       = var.db_username
    db_password                   = var.db_password
    db_name                       = var.db_name
    job_thread_pool_size          = var.job_thread_pool_size
    max_webhook_retry_error_count = var.max_webhook_retry_error_count
    run_async_jobs                = var.run_async_jobs
    request_timeout               = var.request_timeout
  }
}


resource "aws_ecs_task_definition" "hooky_api" {
  family                = "hooky-api"
  container_definitions = data.template_file.containers.api_containers
  task_role_arn         = aws_iam_role.role.arn
  execution_role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
  network_mode          = "host"
  // Check "Task CPU and Memory": https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html
  cpu                      = 512 
  memory                   = 1024 
  requires_compatibilities = ["EC2"]

  /*
  // Leaving the volume block commented because we'd want to run the DB in RDS
  volume {
    name = "pgdata"
    // Leave host_path blank so docker creates our volume: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition#host_path
    // The volume inherits the permissions of the container
    // As long as the directory that the volume is mounted into exists and has correct permissions in the container itself, permissions shouldn't be an issue
  }
  */

  tags = {
    Applicaton   = "hooky"
    HookyVersion = var.container_version
  }
}

resource "aws_ecs_service" "hooky_api" {
  name                               = "hooky-api"
  // We could grab the cluster ID from remote state https://www.terraform.io/docs/providers/terraform/d/remote_state.html
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.hooky_api.arn
  desired_count                      = 3
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 25 // host networking complicates this because we can't run multiple port-bound instances of a container on the same host
  health_check_grace_period_seconds  = 30
  scheduling_strategy                = "REPLICA"
  propagate_tags                     = "TASK_DEFINITION"


  /*
  required when task def network_mode is awsvpc
  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.vault.id]
  }
  */

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "hooky-api"
    container_port   = 5000
  }

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_name
    weight            = 100
  }

  placement_constraints {
    // With host networking, port-bound instances of containers must run on different hosts
    // This also gives us protection against losing an instance
    type = "distinctInstance"
  }

  tags = {
    Application  = "hooky"
    HookyVersion = var.container_version
  }
}
