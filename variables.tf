variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Public subnet CIDR"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  description = "List of private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "admin_cidr" {
  description = "CIDR allowed to SSH into EC2"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "docker_image" {
  description = "Spring PetClinic Docker image"
  type        = string
  default     = "bbodda123/spring-petclinic:latest"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "petclinic"
}

variable "db_username" {
  description = "Database admin user"
  type        = string
  default     = "petclinic"
}

variable "db_password" {
  description = "Database password (no default)"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "ssh_key_name" {
  description = "Optional existing keypair name (leave empty to create one)"
  type        = string
  default     = ""
}

variable "public_ssh_key_path" {
  description = "Path to your public SSH key file to use for instance access (e.g. ~/.ssh/id_ed25519.pub). If empty terraform will generate a keypair."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}
