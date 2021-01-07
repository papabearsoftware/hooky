## Hooky Terraform

### Order of Operations

These modules are broken up by lifecycle. For example, your ASG will share a lifecycle with the cluster, but not the services running _on_ the ASG

`rds/`: Creates the RDS DB. Not needed if you're going to deploy the PostGres container as its own service

`ecr/`: Creates the ECR repo

`ecs/cluster/`: Creates the ASG (and associated resources), ECS cluster, and ALB

`ecs/hooky/`: Creates the ECS service and task definition


### Room For Improvement

The ALB should have a different default rule (like a generic 200 "OK") with different rules. This would allow you to easily reuse the same ALB for multiple applications running in the cluster (you can still reuse it, it just gets confusing if the default rule forwards to a real service). 

## TODO 

Add deployment pipeline
- codepipeline, codebuild, codedeploy
    - blue/green

## Notes

These tasks use the `host` networking mode. When using ECS on EC2, the `awsvpc` networking mode requires a NAT gateway in order for the instance to have internet connectivity. Hooky doesn't seem to need internet connectivity but I won't know until I deploy it. There are a few comments / commented out bits of terraform that should make switching from `host` to `awsvpc` networking simple (though I believe IAM will need some updates).