# jjp6402
Code for Project  
This code is for a specific project and will be retired/removed on the first of August 2026.

# 1. Project Requirements

## 1.1 Summary

1.1.1 Deploy a two-tier cloud-native web application environment in AWS for the technical exercise.

1.1.2 Demonstrate a publicly exposed implementation of the Tasky application running on EKS with a MongoDB v5 database.

1.1.3 Include intentionally insecure configurations stated in the requirement document. These known variances are detailed in Section 4.

1.1.4 Implement security controls, detection, scanning, admission control, CI/CD automation, and validation evidence using the following tools and services:

    1.1.4.1 **Terraform** to provision and manage AWS infrastructure as code.

    1.1.4.2 **AWS CodePipeline** to orchestrate the environment and application deployment workflows.

    1.1.4.3 **AWS CodeBuild** to execute Terraform, security scans, image builds, image signing, deployment, and validation commands.

    1.1.4.4 **Checkov** to scan Terraform/IaC for cloud misconfiguration risk before infrastructure deployment.

    1.1.4.5 **Trivy** to scan the container image for vulnerabilities before deployment. Because the requested implementation requires variances, for the sake of this exercise Trivy is configured to report findings only, but not block. See Section 4 for details.

    1.1.4.6 **AWS ECR** to store the application image.

    1.1.4.7 **AWS Signer and Notation** to sign the container image and verify the image signature before Kubernetes deployment.

    1.1.4.8 **AWS Systems Manager Parameter Store** to store the active generated AWS Signer profile name used by the application pipeline.

    1.1.4.9 **OPA Gatekeeper** to provide Kubernetes validating admission control for cluster policy enforcement.

    1.1.4.10 **AWS Load Balancer Controller** to provision the public Application Load Balancer from Kubernetes Ingress.

    1.1.4.11 **AWS CloudTrail** to provide AWS control-plane audit logging.

    1.1.4.12 **AWS Config** to provide configuration-state visibility and detective control coverage.

    1.1.4.13 **AWS IAM Access Analyzer** to detect externally accessible or overly permissive access paths.

    1.1.4.14 **Kubernetes RBAC** to demonstrate both normal access-control design and the intentionally excessive `cluster-admin` application binding required by the exercise.

    1.1.4.15 **Kubernetes Secrets** to inject MongoDB connection details and application secrets into the workload without committing credentials to source control.

    1.1.4.16 **Application validation scripts** to verify pod health, Ingress exposure, ALB reachability, MongoDB accessibility and the required container txt file.

## 1.2 Bootstrap Requirement

1.2.1 Create the foundational CI/CD resources required to deploy the environment and application.

1.2.2 Create the Terraform backend S3 bucket used for remote environment state.

1.2.3 Create the CodePipeline artifact bucket.

1.2.4 Create the GitHub CodeConnection `jjp6402-github`.

1.2.5 Create the environment pipeline `jjp6402-environment`.

1.2.6 Create the application pipeline `jjp6402-application`.

1.2.7 Create the CodeBuild projects used by the environment and application pipelines:

    1.2.7.1 `jjp6402-environment`.

    1.2.7.2 `jjp6402-app-build`.

    1.2.7.3 `jjp6402-app-deploy`.

    1.2.7.4 `jjp6402-app-validate`.

1.2.8 Create IAM roles and policies required for pipeline execution.

## 1.3 Infrastructure Requirement

1.3.1 Deploy the environment in AWS.

1.3.2 Deploy all runtime resources in AWS region `us-east-2`.

1.3.3 Use Terraform for AWS infrastructure provisioning.

1.3.4 Use EKS for Kubernetes workload hosting.

1.3.5 Use EC2 for the MongoDB VM.

    1.3.5.1 Configure daily MongoDB backups to S3.

1.3.6 Use ECR for container image storage.

1.3.7 Use AWS CodePipeline and CodeBuild for CI/CD automation.

1.3.8 Deploy cloud detective controls using AWS CloudTrail, AWS Config, and IAM Access Analyzer.

1.3.9 Deploy AWS Signer and Systems Manager Parameter Store support for image signing workflows.

1.3.10 Configure EKS platform components after Terraform apply, including OPA Gatekeeper, AWS Load Balancer Controller, namespace, and Kubernetes Secret creation.

## 1.4 Application Requirement

1.4.1 Deploy the Tasky application from `https://github.com/dogukanozdemir/golang-todo-mongodb`.

1.4.2 Expose the application to the internet through AWS ALB and Kubernetes Ingress.

1.4.3 Build the Tasky container image through the application pipeline.

    1.4.3.1 Include the required txt file in the container image.

1.4.4 Scan the Tasky container image with Trivy before deployment.

1.4.5 Push the Tasky image to AWS ECR.

1.4.6 Sign the Tasky image with AWS Signer and Notation.

1.4.7 Verify the Tasky image signature before Kubernetes deployment.

1.4.8 Deploy Tasky to EKS using Kubernetes manifests.

1.4.9 Inject MongoDB connection details and application secrets through Kubernetes Secret `jjp6402-mongodb-app`.

## 1.5 Demonstration Requirement

1.5.1 Demonstrate preventative controls using OPA Gatekeeper and Kubernetes admission control.

1.5.2 Demonstrate detective controls using AWS CloudTrail, AWS Config, and IAM Access Analyzer.

1.5.3 Demonstrate infrastructure scanning using Checkov to identify Terraform/IaC misconfiguration risk.

1.5.4 Demonstrate container image scanning using Trivy to identify operating system and application dependency vulnerabilities.

1.5.5 Demonstrate image integrity controls using AWS Signer and Notation to sign and verify container images before deployment.

1.5.6 Demonstrate Kubernetes access-risk visibility using Kubernetes RBAC and the intentionally excessive `cluster-admin` application binding.

1.5.7 Demonstrate secret handling using Kubernetes Secrets for MongoDB connection details and application secrets.

---

# 2. Project Resources

## 2.1 AWS Resources

2.1.1 AWS Region: `us-east-2`.

2.1.2 AWS VPC.

2.1.3 AWS EKS.

2.1.4 AWS EC2 Ubuntu Server 18.04.

2.1.5 AWS S3.

2.1.6 AWS ECR.

2.1.7 AWS Application Load Balancer.

2.1.8 AWS Load Balancer Controller.

2.1.9 AWS IAM.

2.1.10 AWS CloudTrail.

2.1.11 AWS Config.

2.1.12 AWS IAM Access Analyzer.

2.1.13 AWS CodePipeline.

2.1.14 AWS CodeBuild.

2.1.15 AWS CodeDeploy.

2.1.16 AWS CodeArtifact.

2.1.17 AWS CodeConnections.

2.1.18 AWS Signer.

2.1.19 AWS Systems Manager Parameter Store.

## 2.2 IaC and Security Resources

2.2.1 Terraform `1.15.7`.

2.2.2 Checkov `3.3.7`.

2.2.3 Trivy `v0.72.0`.

2.2.4 Notation CLI `v1.3.2`.

2.2.5 OPA Gatekeeper `v3.22.2`.

2.2.6 `kubectl` `v1.36.2`.

2.2.7 Helm CLI `v3.21.2`.

## 2.3 External Resources

2.3.1 GitHub source code repository `joeljparks/jjp6402`.

## 2.4 Application Resources

2.4.1 MongoDB `5.0.21`.

2.4.2 `dogukanozdemir/golang-todo-mongodb` Go/Gin application container.

2.4.3 MongoDB native database authentication.

2.4.4 Kubernetes Secret for MongoDB application connection string.

---

# 3. Project Design Principles

## 3.1 Naming Convention

3.1.1 VPC name must be `jjp6402`.

3.1.2 Terraform-created AWS resources must use prefix: `jjp6402-`.

## 3.2 Infrastructure as Code

3.2.1 Cloud infrastructure must be deployed with Terraform `1.15.7`.

3.2.2 The environment must be repeatable, auditable, and cleanly destructible.

3.2.3 All applicable AWS resources must be auditable by CloudTrail.

## 3.3 Network Segmentation

3.3.1 All resources must be deployed in private subnets with the exception of MongoDB per design spec. Details must be documented in Section 4.

3.3.2 MongoDB services must only be exposed to the defined Kubernetes cluster network.

3.3.3 Security groups must enforce least privilege.

## 3.4 IAM

3.4.1 IAM permissions must follow least privilege by default.

3.4.2 Wildcard or unnecessary administrative permissions must not be used unless documented as a variance.

3.4.3 Roles must be separated per workload.

3.4.4 Broad permissions must require a documented variance.

## 3.5 Kubernetes Security

3.5.1 Workloads must use dedicated service accounts.

3.5.2 RBAC must be limited to minimum required namespaces and API resources by default.

3.5.3 Workloads must not use `cluster-admin` unless documented as a variance. See Section 4 for these variances.

3.5.4 Containers on EKS must not run as root.

## 3.6 Data Protection

3.6.1 Backups must not be public by default.

3.6.2 Object storage must not allow public listing by default.

3.6.3 Secrets must not be hardcoded.

3.6.4 MongoDB must use native database authentication.

3.6.5 MongoDB credentials must not be committed to source control.

3.6.6 Kubernetes workloads must receive the MongoDB connection string through environment variables.

## 3.7 Lifecycle

3.7.1 Supported operating systems and database versions must be used by default.

3.7.2 Operating systems, images, and dependencies must be patched.

3.7.3 End-of-life components must require a documented variance. See Section 4 for more information.

3.7.4 Tooling, packages, binaries, container images, and dependencies must be pinned to stable GA versions; floating latest, alpha, beta, RC, nightly, and dev builds are not allowed.

## 3.8 CI/CD Security

3.8.1 Code and infrastructure changes must flow through source control.

3.8.2 Pipelines must scan Terraform environment code before deployment.

3.8.3 Pipelines must scan container images before deployment.

3.8.4 Deployment must be automated and repeatable.

3.8.5 All workflows must use ephemeral credentials.

3.8.6 Long-lived static cloud keys must not be used in CI/CD.

3.8.7 Application build dependencies must be sourced from a private artifact repository.

3.8.8 Environment deployment dependencies must be sourced from a private artifact repository.

3.8.9 Required third-party binaries, packages, and libraries must be staged into AWS CodeArtifact during pre-staging.

3.8.10 Build and deployment pipelines must consume CodeArtifact dependencies rather than public internet sources.

3.8.11 Direct internet dependency retrieval during normal build and deployment must be disallowed unless documented as a variance. Variances can be found in Section 4.

3.8.12 Container images must be signed at build time.

3.8.13 Container images must be tagged with build numbers.

    3.8.13.1 Build numbers must follow SemVer.

    3.8.13.2 Initial SemVer must be `1.1.1`.

3.8.14 The application deployment pipeline must verify image signatures before deployment; unsigned images must not be deployed.

## 3.9 Terraform State Management

3.9.1 Terraform state must use a remote secured backend.

3.9.2 Terraform state must use an S3 backend.

3.9.3 Terraform state must be encrypted.

3.9.4 Terraform state versioning must be enabled.

3.9.5 Terraform state locking must be enabled with an S3 lockfile.

3.9.6 Terraform state access must be restricted to CI/CD roles and administrators.

3.9.7 Terraform state must not be committed to source control.

3.9.8 CodeArtifact must be used for dependencies, not Terraform state.

## 3.10 Code Standards

3.10.1 Code comments must be terse.

3.10.2 Comments must explain the intent of an action but no more. Do not editorialize.

---

# 4. Project Variances

4.0 Variances listed in this section are known departures from best practice and must be regarded as approved overrides to the design principles stated in Section 3. These variances are required by the exercise and must not be treated as production-ready design patterns. If you do, may God have mercy on your soul.

## 4.1 MongoDB VM in Public Subnet

4.1.1 The MongoDB EC2 VM must be deployed in a public subnet.

4.1.2 The MongoDB EC2 VM must use public subnet CIDR `10.0.0.0/24`.

4.1.3 MongoDB service access on TCP/27017 must remain restricted to the defined Kubernetes cluster network.

## 4.2 Public SSH to MongoDB VM

4.2.1 The MongoDB EC2 VM must expose SSH on TCP/22 publicly.

4.2.2 The SSH security group rule must allow TCP/22 from `0.0.0.0/0`.

## 4.3 Outdated Linux Operating System

4.3.1 The MongoDB EC2 VM must run Ubuntu Server 18.04 LTS.

## 4.4 Outdated MongoDB Version

4.4.1 MongoDB must run version `5.0.21`.

## 4.5 Public S3 Backup Bucket

4.5.1 The MongoDB backup bucket must be named `jjp6402-mongo5-backup`.

4.5.2 The MongoDB backup bucket must allow public read.

4.5.3 The MongoDB backup bucket must allow public listing.

4.5.4 S3 public access block must be disabled for the MongoDB backup bucket.

## 4.6 Overly Permissive EC2 Role

4.6.1 The MongoDB EC2 instance role must include permissions beyond backup requirements.

4.6.2 The MongoDB EC2 instance role must include the ability to create EC2 instances.

## 4.7 Cluster-Wide Kubernetes Admin Role and Privilege

4.7.1 The container application must be assigned cluster-wide Kubernetes admin role and privilege.

4.7.2 The application service account must be bound to `cluster-admin`.

4.7.3 The `cluster-admin` binding must apply only to the exercise workload.
