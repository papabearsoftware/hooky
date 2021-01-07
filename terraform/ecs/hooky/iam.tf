resource "aws_iam_role" "role" {
  name = "hooky-api-container-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com", "ec2.amazonaws.com"]
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

// Hooky doesn't need to interact with any AWS services aside from RDS, which uses user/pass auth, so no policies attached here
// If hooky wanted to implement, say, queueing, we could attach an SQS policy here