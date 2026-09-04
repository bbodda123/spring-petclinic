# Terraform Infrastructure Plan — Spring PetClinic

## Objective

Build a Terraform infrastructure for the Spring PetClinic application on AWS.

The first version should be intentionally simple and focused on:

1. Creating an SSH key pair with Terraform.
2. Creating an AWS VPC/network.
3. Creating an RDS PostgreSQL database.
4. Creating an EC2 Ubuntu instance.
5. Installing Docker automatically on the EC2 instance.
6. Pulling and running the Spring PetClinic Docker image from Docker Hub.
7. Connecting the Spring PetClinic container on EC2 to the RDS PostgreSQL database.
8. Providing useful Terraform outputs.
9. Keeping secrets and private keys out of Git.

Do NOT implement ECS, ALB, Auto Scaling, NAT Gateway, Route53, HTTPS, or CloudWatch dashboards yet.

---

## Target Architecture

```text
                         Internet
                            |
                            |
                       Public Subnet
                            |
                            v
                    +---------------+
                    |      EC2      |
                    |    Ubuntu     |
                    |               |
                    |    Docker     |
                    |       |       |
                    |       v       |
                    | Spring        |
                    | PetClinic     |
                    +-------+-------+
                            |
                            | TCP 5432
                            |
                            v
                    +---------------+
                    |      RDS      |
                    |  PostgreSQL   |
                    |               |
                    |   petclinic   |
                    +---------------+
                       Private subnet
```

---

# 1. Terraform Project Structure

Create the following structure:

```text
terraform/
├── versions.tf
├── provider.tf
├── variables.tf
├── network.tf
├── security-groups.tf
├── key-pair.tf
├── ec2.tf
├── rds.tf
├── outputs.tf
├── terraform.tfvars.example
├── user-data.sh
└── .gitignore
```

Keep the Terraform configuration modular by responsibility.

---

# 2. Terraform Providers

Use:

* AWS provider
* TLS provider for SSH key generation

Use current stable provider versions compatible with the installed Terraform version.

The AWS region must be configurable through a variable.

Example:

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
}
```

Do not hardcode the region throughout the configuration.

---

# 3. VPC / Networking

Create a dedicated VPC for the application.

Requirements:

* VPC CIDR: `10.0.0.0/16`
* One public subnet for EC2.
* One or more private subnets for RDS.
* Internet Gateway for the public subnet.
* Route table for the public subnet.
* Associate the public subnet with the public route table.

The EC2 must have internet access so it can:

* Install Docker.
* Pull the Docker image from Docker Hub.
* Allow SSH access.

RDS should not be publicly accessible.

For the first version, avoid NAT Gateway unless it is actually required.

---

# 4. SSH Key Pair

Generate an SSH key pair using Terraform.

Use the TLS provider to generate the private/public key.

Requirements:

* Generate an RSA or ED25519 key.
* Register the public key with AWS as an EC2 Key Pair.
* Make the private key available locally for SSH access.
* Do NOT commit the private key to Git.
* Set appropriate permissions on the private key (`chmod 600`).

Preferred approach:

```text
Terraform
   |
   +-- Generate private/public key
   |
   +-- AWS receives public key
   |
   +-- Private key stored locally
```

If Terraform creates the private key as a sensitive output, mark it:

```hcl
sensitive = true
```

Do not expose the private key in normal Terraform output.

The final SSH command should be:

```bash
ssh -i <private-key> ubuntu@<EC2_PUBLIC_IP>
```

---

# 5. Security Groups

Create separate security groups for EC2 and RDS.

## EC2 Security Group

Allow:

### SSH

```text
Port: 22
Protocol: TCP
Source: configurable administrator IP/CIDR
```

Do NOT blindly expose SSH to the entire internet if avoidable.

Make the SSH CIDR configurable:

```hcl
variable "admin_cidr" {
  description = "CIDR allowed to SSH into EC2"
  type        = string
}
```

### Spring PetClinic

Allow:

```text
Port: 8080
Protocol: TCP
Source: 0.0.0.0/0
```

This is acceptable for the initial version so the application can be accessed from the browser.

---

## RDS Security Group

Allow:

```text
Port: 5432
Protocol: TCP
Source: EC2 security group
```

Do NOT allow:

```text
0.0.0.0/0 -> 5432
```

The database must only accept PostgreSQL connections originating from the EC2 security group.

The intended traffic flow is:

```text
Internet
   |
   v
EC2 :8080
   |
   | EC2 SG -> RDS SG
   |
   v
RDS :5432
```

---

# 6. RDS PostgreSQL

Create an Amazon RDS PostgreSQL instance.

Requirements:

* PostgreSQL engine.
* Database name: `petclinic`.
* Configurable username.
* Configurable password.
* RDS deployed in private subnet(s).
* `publicly_accessible = false`.
* Attach the RDS security group.
* Create a DB subnet group.
* Enable deletion protection only if appropriate for the environment; this is a development environment, so avoid making cleanup unnecessarily difficult.
* Use a small cost-conscious instance suitable for development/testing.

The following values must be variables:

```text
db_name
db_username
db_password
db_instance_class
```

Do not hardcode the database password in Terraform source files.

---

# 7. RDS Output

Create Terraform outputs for:

```text
rds_endpoint
rds_port
rds_database_name
```

The important output should look conceptually like:

```text
rds_endpoint = "petclinic.xxxxxxxxx.region.rds.amazonaws.com:5432"
```

The endpoint will be used by the Spring application.

---

# 8. EC2 Instance

Create an Ubuntu EC2 instance.

Requirements:

* Ubuntu AMI.
* AMI ID should be configurable or selected using an appropriate AWS data source.
* Small cost-conscious instance type suitable for development.
* Attach the generated AWS key pair.
* Attach EC2 security group.
* Place EC2 in the public subnet.
* Enable a public IP.
* Use Terraform/user-data to configure the instance.

Outputs should include:

```text
ec2_public_ip
ec2_public_dns
ec2_instance_id
```

---

# 9. EC2 User Data

Create a separate:

```text
user-data.sh
```

The script should:

1. Update apt packages.
2. Install Docker.
3. Start Docker.
4. Enable Docker on boot.
5. Configure the Ubuntu user to use Docker without sudo where appropriate.
6. Pull the Spring PetClinic Docker image from Docker Hub.
7. Start the Spring PetClinic container.

Do not put secrets directly into the Git repository.

---

# 10. Spring PetClinic Docker Image

The EC2 should run the existing Docker Hub image:

```text
bbodda123/spring-petclinic:latest
```

Make the Docker image configurable:

```hcl
variable "docker_image" {
  description = "Spring PetClinic Docker image"
  type        = string
  default     = "bbodda123/spring-petclinic:latest"
}
```

The EC2 should execute the equivalent of:

```bash
docker pull bbodda123/spring-petclinic:latest
```

and:

```bash
docker run -d \
  --name spring-petclinic \
  -p 8080:8080 \
  ...
```

---

# 11. Spring → RDS Configuration

The Spring application must use the RDS endpoint instead of localhost.

The container environment should contain:

```text
SPRING_PROFILES_ACTIVE=postgres
SPRING_DATASOURCE_URL=jdbc:postgresql://<RDS_ENDPOINT>:5432/petclinic
SPRING_DATASOURCE_USERNAME=<DB_USERNAME>
SPRING_DATASOURCE_PASSWORD=<DB_PASSWORD>
```

Important:

Do NOT use:

```text
jdbc:postgresql://localhost:5432/petclinic
```

because PostgreSQL is running on RDS, not inside the EC2 host.

---

# 12. Secrets Handling

Do not commit:

```text
DB password
SSH private key
Terraform state
terraform.tfvars containing secrets
.env files
```

The `.gitignore` should include:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.pem
*.key
terraform.tfvars
.env
```

Create:

```text
terraform.tfvars.example
```

containing example/non-secret values.

---

# 13. Terraform Outputs

Create these outputs:

```text
ec2_instance_id
ec2_public_ip
ec2_public_dns
rds_endpoint
rds_port
rds_database_name
```

Optionally:

```text
ssh_command
```

Example:

```text
ssh_command = "ssh -i petclinic.pem ubuntu@<EC2_PUBLIC_IP>"
```

Do not expose passwords or private keys through normal outputs.

---

# 14. Terraform Variables

At minimum:

```text
aws_region
environment
vpc_cidr
public_subnet_cidr
private_subnet_cidrs
admin_cidr
instance_type
docker_image
db_name
db_username
db_password
db_instance_class
```

Use sensible development defaults where safe.

Never provide a default database password.

---

# 15. Terraform Dependency Requirements

Ensure Terraform understands the dependencies.

Conceptually:

```text
VPC
 |
 +---- Public subnet ------> EC2
 |
 +---- Private subnets ----> RDS
 |
 +---- Security Groups
 |
 +---- DB subnet group
```

The EC2 container configuration must receive the RDS endpoint.

Do not use hardcoded RDS hostnames.

Use Terraform references.

---

# 16. Validation

After:

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

verify:

### EC2

```bash
ssh -i petclinic.pem ubuntu@<EC2_PUBLIC_IP>
```

Then:

```bash
docker ps
```

Verify the PetClinic container is running.

---

### Application

Open:

```text
http://<EC2_PUBLIC_IP>:8080
```

The Spring PetClinic application should load.

---

### Database connectivity

Verify the application logs:

```bash
docker logs spring-petclinic
```

There should be no PostgreSQL connection errors.

The application should successfully connect to:

```text
RDS PostgreSQL
```

---

# 17. Acceptance Criteria

The implementation is considered complete when all of the following are true:

* [ ] `terraform init` succeeds.
* [ ] `terraform validate` succeeds.
* [ ] `terraform plan` succeeds.
* [ ] Terraform creates the VPC.
* [ ] Terraform creates the public subnet.
* [ ] Terraform creates the private subnet(s).
* [ ] Terraform creates the Internet Gateway.
* [ ] Terraform creates the route tables.
* [ ] Terraform creates the EC2 security group.
* [ ] Terraform creates the RDS security group.
* [ ] Terraform generates an SSH key pair.
* [ ] EC2 key pair is registered with AWS.
* [ ] EC2 is created successfully.
* [ ] RDS PostgreSQL is created successfully.
* [ ] RDS is not publicly accessible.
* [ ] RDS accepts port 5432 only from the EC2 security group.
* [ ] Docker is automatically installed on EC2.
* [ ] Spring PetClinic image is pulled from Docker Hub.
* [ ] Spring PetClinic container starts automatically.
* [ ] Spring PetClinic uses the RDS endpoint.
* [ ] Spring PetClinic is accessible on port 8080.
* [ ] RDS endpoint is exposed through Terraform output.
* [ ] EC2 public IP is exposed through Terraform output.
* [ ] SSH private key is not committed to Git.
* [ ] Terraform state is not committed to Git.
* [ ] No database password is hardcoded in the repository.

---

# 18. Future Phase — Do Not Implement Yet

Once this first version works, the infrastructure can be extended with:

```text
Phase 2:
CloudWatch
├── EC2 monitoring
├── Application logs
├── RDS monitoring
└── Alarms

Phase 3:
AWS Billing
├── CloudWatch billing alarm
├── AWS Budget
└── Cost alerts

Phase 4:
CI/CD
GitHub Actions
      |
      v
Docker Hub / ECR
      |
      v
EC2 deployment

Phase 5:
Production architecture
├── ALB
├── HTTPS
├── Auto Scaling
├── ECS/ECS Fargate
├── Secrets Manager
└── High availability
```

For now, **only implement Phase 1**.

The goal is to get this working end-to-end:

```text
Terraform
   |
   +--> VPC
   |
   +--> SSH Key
   |
   +--> EC2
   |      |
   |      +--> Docker
   |             |
   |             +--> Spring PetClinic
   |
   +--> RDS PostgreSQL
          ^
          |
          +---- EC2 :5432

Spring PetClinic
       |
       v
RDS PostgreSQL
```

