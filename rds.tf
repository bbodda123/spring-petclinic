resource "aws_db_subnet_group" "db_subnets" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags = { Name = "${var.environment}-db-subnet-group" }
}

resource "aws_db_instance" "default" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "17"
  instance_class       = var.db_instance_class
  db_name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
  tags = { Name = "${var.environment}-rds" }
}
