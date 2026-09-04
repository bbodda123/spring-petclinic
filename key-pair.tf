resource "tls_private_key" "deployer" {
  # Generate a new keypair only if the user has not provided a public key path if the count = 0 the resource will not be created
  count     = var.public_ssh_key_path == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_key_name != "" ? var.ssh_key_name : "${var.environment}-deployer"
  public_key = var.public_ssh_key_path != "" ? file(var.public_ssh_key_path) : tls_private_key.deployer[0].public_key_openssh
}

output "private_key_pem" {
  description = "Private key PEM (sensitive). Only populated when Terraform generates a keypair."
  value       = var.public_ssh_key_path == "" ? tls_private_key.deployer[0].private_key_pem : ""
  sensitive   = true
}

# Note: when using a generated key, consider writing the private key to disk with a secure local_file resource
