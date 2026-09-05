# Ansible Application Deployment

Ansible configures the EC2 host and deploys the Spring PetClinic Docker image. Terraform is documented separately in [`infrastructure/terraform/README.md`](../terraform/README.md) and must provision the target host first.

## Prerequisites

- Ansible installed on the control machine.
- A running EC2 or VPS host created by Terraform or another provisioning tool.
- SSH access using the configured private key.
- DNS pointing to the host before the SSL role runs.
- Docker Hub and application environment values stored securely.

## Configure the target

1. Update `inventory/hosts.yml` with the host address, SSH user, and private key path.
2. Update `group_vars/all/vars.yml` with the domain, host values, image version, and runtime settings.
3. Store secrets in `group_vars/all/vault.yml` with `ansible-vault`; do not commit plaintext credentials.
4. Confirm that the Docker image tag and runtime `.env` values match the image published by CI/CD.

## Run the playbook

Run these commands from `infrastructure/ansible/`:

```bash
ansible all -m ping
ansible-playbook -i inventory/hosts.yml site.yml --check
ansible-playbook -i inventory/hosts.yml site.yml
```

Use `--ask-become-pass` when the remote host requires an interactive sudo password.

## Roles

The playbook runs these roles in order:

1. `common` installs base packages and applies host defaults.
2. `docker` installs and configures Docker.
3. `nginx_ssl` installs Nginx and Certbot, configures the reverse proxy, and requests the certificate.
4. `deploy_app` writes the Compose file and runtime environment, starts the published image, and waits for port 8080.
5. `security_hardening` applies firewall and host hardening settings.

## Verify deployment

```bash
curl -I https://your-domain.example
ssh -i ~/.ssh/petclinic.pem ubuntu@your-host 'docker ps'
```

On the host, also verify the container logs, Nginx configuration, TLS renewal, and that port 8080 is not unnecessarily exposed publicly. The exact Compose directory is controlled by the Ansible variables, so confirm it before using host-level commands.

## CI/CD handoff

The application repository's [CI/CD documentation](../../spring-petclinic/docs/CI-CD.md) explains how GitHub Actions publishes the image and invokes this playbook. Before enabling automatic deployment, verify that the workflow checks out this Ansible code, supplies its inventory and `.env`, and runs from the expected working directory.
