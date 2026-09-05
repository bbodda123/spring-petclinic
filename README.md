# Terraform Infrastructure

Terraform provisions the AWS resources used by Spring PetClinic. Ansible is documented separately in [`infrastructure/ansible/README.md`](../ansible/README.md) and runs after the target host is available.

## Prerequisites

- Terraform compatible with the version in `versions.tf`.
- AWS credentials with permission to manage the declared resources.
- An AWS region and an existing or generated SSH key pair.
- A local `terraform.tfvars` file containing environment-specific values. Never commit credentials or private keys.

## Plan and apply

Run these commands from `infrastructure/terraform/`:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Inspect the connection and service values after applying:

```bash
terraform output
terraform output -raw eip_public_ip
terraform output -raw rds_endpoint
```

The configuration provisions a VPC and subnets, an EC2 application host, an Elastic IP, an RDS database, security groups, and an SSH key pair.

Review `admin_cidr` before applying. The default in `variables.tf` allows SSH from anywhere and should be restricted to a trusted CIDR.

## Destroy

Destroy only when the environment is no longer needed:

```bash
terraform destroy
```

Review the plan carefully because destroying the stack can remove the database and other persistent resources.

## Verification checklist

- `terraform fmt -check`, `terraform validate`, and `terraform plan` succeed.
- AWS region, account, VPC CIDRs, `admin_cidr`, and key pair are correct.
- RDS credentials are stored securely and database backups and deletion protection are understood.
- Terraform state is stored securely and backed up according to the team's recovery policy.
- The generated EC2 public IP or DNS name is reachable with the configured SSH key.
- Terraform destroy is tested only in a disposable environment and its impact on RDS is understood.

## Handoff to Ansible

After `terraform apply`, pass the EC2 public IP, SSH key, SSH user, database endpoint, and DNS name to the Ansible configuration. Then continue with [`infrastructure/ansible/README.md`](../ansible/README.md).
