# Subnet group
resource "aws_db_subnet_group" "this" {
  name       = "${var.env}-db-subnet-group"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = {
    Name = "${var.env}-db-subnet-group"
  }
}

# Pull DB password from AWS Secrets Manager
data "aws_secretsmanager_secret" "db" {
  name = var.db_secret_name   # e.g. "mydb-secret"
}

data "aws_secretsmanager_secret_version" "db" {
  secret_id = data.aws_secretsmanager_secret.db.id
}

resource "aws_db_instance" "appdb" {
  identifier              = "${var.env}-rds"
  allocated_storage       = 20
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = var.rds_instance_class
  db_name                 = var.db_name
  username                = var.db_username

  # 👇 Now securely pulled from Secrets Manager
  password                = jsondecode(
                               data.aws_secretsmanager_secret_version.db.secret_string
                             )["password"]

  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  multi_az                = true
  publicly_accessible     = false
  backup_retention_period = 7
  apply_immediately       = true

  tags = {
    Name = "${var.env}-rds"
  }
}
