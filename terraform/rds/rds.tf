resource "aws_rds_cluster" "cluster" {
  cluster_identifier      = "hooky"
  engine                  = "aurora-postgresql"
  engine_version          = "11.9"
  availability_zones      = ["us-east-1a", "us-east-1b"]
  database_name           = "hooky"
  master_username         = var.db_superuser_username
  master_password         = var.db_superuser_password
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"
  // TODO add more settings
}

// TODO create param, option, and subnet groups

resource "aws_rds_cluster_instance" "cluster_instances" {
  count              = var.number_of_instances
  identifier         = "hooky-${count.index}"
  cluster_identifier = aws_rds_cluster.cluster.id
  instance_class     = var.db_instance_type
  engine             = aws_rds_cluster.cluster.engine
  engine_version     = aws_rds_cluster.default.engine_version
}

