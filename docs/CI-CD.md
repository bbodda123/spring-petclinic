# CI/CD Documentation

This document describes the GitHub Actions workflows for Spring PetClinic and the checks required before relying on automated deployment.

## Workflow overview

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| [`ci.yml`](../.github/workflows/ci.yml) | Push or pull request targeting `main` | Tests and packages the application. On a non-PR push it also publishes a Docker image and deploys with Ansible. |
| [`maven-build.yml`](../.github/workflows/maven-build.yml) | Manual run, or `k8s/**` changes on `main` | Runs `./mvnw -B verify` with Java 17. |
| [`gradle-build.yml`](../.github/workflows/gradle-build.yml) | Manual run, or `k8s/**` changes on `main` | Runs `./gradlew build` with Java 17. |
| [`deploy-and-test-cluster.yml`](../.github/workflows/deploy-and-test-cluster.yml) | Manual run, or `k8s/**` changes on `main` | Creates a Kind cluster, applies the Kubernetes manifests, and waits for the database and application pods. |

The Maven and Gradle workflows are independent validation workflows. The `ci.yml` workflow is the deployment pipeline.

Infrastructure responsibilities are documented separately:

- [Terraform AWS provisioning](../../infrastructure/terraform/README.md)
- [Ansible host and application deployment](../../infrastructure/ansible/README.md)

## Main pipeline

The `ci.yml` workflow has three jobs:

1. **test** checks out the code, creates `.env` from `ENV_TEST`, uses Temurin Java 17, and runs `./mvnw clean package`. Surefire reports are uploaded as the `test-reports` artifact even when the test step fails.
2. **docker-publish** runs only for a non-pull-request event after the test job. It pushes both `latest` and the commit SHA tag to Docker Hub.
3. **deploy** runs after the image is published. It authenticates to AWS, applies Terraform changes that allow the GitHub runner to connect, tests SSH, installs Ansible, runs the playbook, and destroys the temporary Terraform access rule in an `always()` step.

## Required GitHub configuration

Configure these repository or environment secrets before running the pipeline:

| Secret | Used by |
| --- | --- |
| `ENV_TEST` | Test job `.env` file |
| `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` | Docker Hub login and image tags |
| `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` | Terraform and AWS identity check |
| `DEPLOY_KEY` | SSH private key for the deployment host |
| `HOST_PUBLIC_IP` | SSH target used by the deploy job |
| `ENV_FILE` | Runtime `.env` copied by the Ansible `deploy_app` role |

The workflow refers to the environments `test`, `production`, and `ansible`. Verify that these environments exist and that their protection rules and secrets are intentional.

## How to run CI/CD

### Pull request verification

1. Open a pull request targeting `main`.
2. Confirm that the `CI` workflow starts and that the test report artifact is available.
3. For Kubernetes changes, confirm that the Maven, Gradle, and Kind workflows also run. Check the path filters carefully because the Maven and Gradle workflow files currently use `/k8s/**`, while the Kind workflow uses `k8s/**`.

### Application build and deployment

1. Merge or push a commit to `main`.
2. In GitHub, open **Actions**, select **CI**, and open the run for the commit.
3. Verify the `test` job, then confirm the Docker Hub tags for both `latest` and the commit SHA.
4. Verify the AWS identity and SSH checks in the `deploy` job.
5. Confirm that Ansible reports a successful playbook and that the application responds through the configured domain.
6. Confirm the final Terraform cleanup step succeeds, including when an earlier deployment step fails.

## Required end-to-end verification

Before treating deployment as operational, verify these repository assumptions in a real GitHub Actions run:

- The `feat/infra-ansible` ref checked out by the deploy job exists and contains the `terraform/` and `inventory/` paths used by later steps.
- The deploy job's `terraform` working directory contains the Terraform configuration expected by the workflow.
- `inventory/hosts.yml`, `site.yml`, the Ansible roles, and `roles/deploy_app/files/.env` are present relative to the deploy job's current directory.
- The Terraform configuration can apply and destroy its temporary GitHub runner access without affecting permanent application access.
- The Docker image tag consumed by Ansible matches the tag published by `docker-publish`.
- The host, DNS record, TLS certificate, database connection, and application health endpoint all work after deployment.
- A failed test really blocks publication. At present, the test step has `continue-on-error: true`; this should be deliberately tested and either accepted as policy or changed before using CI as a release gate.

## Local checks

Run the same build checks locally from `spring-petclinic/`:

```bash
./mvnw clean package
./mvnw -B verify
./gradlew build
```

For the Kubernetes workflow, use a local Kind cluster and then inspect the resources:

```bash
kind create cluster
kubectl apply -f k8s/
kubectl get pods
kubectl wait --for=condition=ready pod -l app=demo-db --timeout=180s
kubectl wait --for=condition=ready pod -l app=petclinic --timeout=180s
```

Do not place credentials in workflow files, committed `.env` files, or Terraform state. Treat Terraform state and CI logs as sensitive because they can contain infrastructure details.