resource "aws_vpc_security_group_ingress_rule" "github_runner_ssh" {
  security_group_id = "sg-014afded2a4f4ab4e"

  description = "SSH from GitHub Actions runner"

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22

  cidr_ipv4 = local.admin_cidr
}