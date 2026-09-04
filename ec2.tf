data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true

  # user_data = templatefile("${path.module}/user-data.sh", {
  #   db_endpoint = aws_db_instance.default.address
  #   db_port     = aws_db_instance.default.port
  #   db_name     = var.db_name
  #   db_user     = var.db_username
  #   db_pass     = var.db_password
  #   docker_image = var.docker_image
  # })

  tags = { Name = "${var.environment}-ec2" }
}

resource "aws_eip" "app_eip" {
  vpc = true

  tags = {
    Name = "${var.environment}-app-eip"
  }
}

resource "aws_eip_association" "app_eip_assoc" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app_eip.id
}
