# Enterprise Cloud Security Platform on AWS

## Overview

This project is a Terraform-managed AWS platform built around Amazon EKS. It provisions the underlying network, compute, access controls, monitoring, and Kubernetes workload required to run a small production-style platform environment.

The project demonstrates practical cloud and platform engineering across AWS, Terraform, Kubernetes, and infrastructure operations.

The current environment runs in `af-south-1` and consists of an Amazon VPC, public and private subnets across two availability zones, NAT connectivity, an Amazon EKS cluster, a managed node group, and a Kubernetes application deployed into a dedicated namespace.

## Architecture

```text
                              AWS
                               │
                       ┌───────▼───────┐
                       │      VPC      │
                       │   10.0.0.0/16 │
                       └───────┬───────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
       Public Subnets                    Private Subnets
              │                                 │
       ┌──────▼──────┐                 ┌────────▼────────┐
       │ NAT Gateway │────────────────►│   EKS Cluster   │
       └─────────────┘                 │                 │
                                       │ Managed Nodes   │
                                       └────────┬────────┘
                                                │
                                           Kubernetes
                                                │
                                      ┌─────────▼─────────┐
                                      │  platform         │
                                      │  namespace        │
                                      └─────────┬─────────┘
                                                │
                                      ┌─────────▼─────────┐
                                      │   platform-api    │
                                      │    Deployment     │
                                      │    2 replicas     │
                                      └─────────┬─────────┘
                                                │
                                      ┌─────────▼─────────┐
                                      │    ClusterIP      │
                                      │      Service      │
                                      └───────────────────┘

                         EKS Control Plane
                                │
                                ▼
                         CloudWatch Logs
```

## What was built

### AWS infrastructure

The infrastructure is provisioned through Terraform using reusable modules.

The environment includes:

* Amazon VPC
* Public and private subnets across two availability zones
* Internet Gateway
* NAT Gateway
* Public and private route tables
* Route table associations
* Platform Security Group
* Amazon EKS cluster
* EKS managed node group
* IAM roles and required AWS-managed policies
* CloudWatch log groups for EKS logging

### Amazon EKS

The development environment runs an Amazon EKS cluster with:

* Kubernetes version `1.35`
* Cluster status `ACTIVE`
* Managed node group
* Desired capacity: `2`
* Minimum capacity: `2`
* Maximum capacity: `3`
* Instance type: `t3.medium`
* Worker nodes deployed into private subnets

The EKS control plane has logging enabled for:

* API server
* Audit
* Authenticator
* Controller Manager
* Scheduler

Control-plane logs are delivered to CloudWatch with a 30-day retention period.

## Kubernetes workload

The application is deployed into a dedicated `platform` namespace.

```text
platform/
├── ConfigMap
├── ServiceAccount
├── NetworkPolicy
├── Deployment
└── ClusterIP Service
```

### Deployment

`platform-api` runs two replicas using the `nginx:1.27-alpine` container image.

The deployment includes:

* Two replicas
* RollingUpdate deployment strategy
* CPU and memory requests
* CPU and memory limits
* Readiness probe
* Liveness probe
* ConfigMap-based environment configuration

The configured application values are:

```text
APP_ENV=dev
APP_NAME=enterprise-cloud-security-platform
LOG_LEVEL=INFO
```

### Service

The application is exposed internally through a Kubernetes `ClusterIP` service.

```text
Service:     platform-api
Type:        ClusterIP
Port:        80
Target Port: 80
```

The service routes traffic to the application pods running in the cluster.

## Kubernetes network control

A Kubernetes NetworkPolicy is applied to the `platform-api` pods.

The policy controls ingress traffic to port `80/TCP` and permits traffic from workloads in the `platform` namespace.

This provides workload-level network segmentation in addition to the AWS VPC and Security Group controls.

## Terraform structure

The Terraform configuration is organised into reusable modules.

```text
terraform/
├── bootstrap/
│   ├── kms.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   └── variables.tf
│
├── environments/
│   └── dev/
│       ├── backend.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── platform-app.yaml
│       ├── platform-config.yaml
│       ├── platform-networkpolicy.yaml
│       ├── platform-serviceaccount.yaml
│       ├── providers.tf
│       └── variables.tf
│
└── modules/
    ├── eks/
    ├── monitoring/
    ├── networking/
    └── security/
```

### Terraform modules

#### Networking

Responsible for the underlying VPC networking:

* VPC
* Subnets
* Internet Gateway
* NAT Gateway
* Route tables
* Route associations

#### EKS

Responsible for the Kubernetes control plane and managed worker nodes:

* EKS cluster
* Cluster IAM role
* Node IAM role
* Managed node group
* Required IAM policy attachments

#### Security

Responsible for AWS-level network access controls, including the platform Security Group.

#### Monitoring

Responsible for CloudWatch logging associated with the platform and EKS cluster.

## Infrastructure state

Terraform state is managed separately from the application infrastructure configuration through the project's bootstrap and environment configuration.

Terraform state files are not committed to the repository.

## Deployment

### Prerequisites

The environment requires:

* AWS CLI
* Terraform
* kubectl
* An AWS identity with permissions to provision the required infrastructure
* An AWS region configured for the deployment

The project was deployed in:

```text
af-south-1
```

### Initialize Terraform

From the development environment:

```powershell
cd terraform\environments\dev

terraform init
```

### Review the infrastructure

```powershell
terraform plan
```

The final validation returned:

```text
No changes. Your infrastructure matches the configuration.
```

### Apply the infrastructure

```powershell
terraform apply
```

### Configure kubectl

```powershell
aws eks update-kubeconfig `
  --region af-south-1 `
  --name enterprise-cloud-security-platform-dev-eks
```

Verify the nodes:

```powershell
kubectl get nodes
```

### Deploy the Kubernetes resources

Create the namespace if it does not already exist:

```powershell
kubectl create namespace platform
```

If the namespace already exists, Kubernetes will return `AlreadyExists`; this does not indicate a deployment failure.

Apply the application configuration:

```powershell
kubectl apply -f .\platform-config.yaml
kubectl apply -f .\platform-serviceaccount.yaml
kubectl apply -f .\platform-networkpolicy.yaml
kubectl apply -f .\platform-app.yaml
```

Check the deployment:

```powershell
kubectl rollout status deployment/platform-api -n platform
```

## Validation

The environment was validated at both the AWS and Kubernetes layers.

### Terraform

```text
No changes. Your infrastructure matches the configuration.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

### EKS cluster

```text
Name:     enterprise-cloud-security-platform-dev-eks
Status:   ACTIVE
Version:  1.35
```

### Node group

```text
Status:          ACTIVE
Desired:         2
Minimum:         2
Maximum:         3
Instance type:   t3.medium
```

### Kubernetes nodes

Both worker nodes reported `Ready`.

```text
NAME                                        STATUS
ip-10-0-11-5.af-south-1.compute.internal    Ready
ip-10-0-12-52.af-south-1.compute.internal   Ready
```

### Application pods

The deployment was rolled out successfully with two running replicas.

```text
NAME                           READY   STATUS
platform-api-745bbd545-22btq   1/1     Running
platform-api-745bbd545-zjn4p   1/1     Running
```

### Service

```text
NAME           TYPE        CLUSTER-IP     PORT(S)
platform-api   ClusterIP   172.20.31.15   80/TCP
```

### NetworkPolicy

```text
NAME           POD-SELECTOR
platform-api   app=platform-api
```

The policy permits ingress to port `80/TCP` from workloads in the `platform` namespace.

### Service connectivity

Connectivity was tested from a temporary pod inside the Kubernetes cluster:

```powershell
kubectl run test-client `
  -n platform `
  --image=curlimages/curl:8.12.1 `
  --rm -it `
  --restart=Never `
  -- curl -I http://platform-api
```

The service returned:

```text
HTTP/1.1 200 OK
```

This confirmed that the Kubernetes Service correctly routes traffic to the application pods.

### EKS logging

The following EKS control-plane log types are enabled:

```text
api
audit
authenticator
controllerManager
scheduler
```

The cluster log group is:

```text
/aws/eks/enterprise-cloud-security-platform-dev-eks/cluster
```

Configured retention:

```text
30 days
```

## Monitoring and logging

CloudWatch provides centralized logging for the EKS control plane.

The logging configuration covers:

* API server activity
* Kubernetes audit events
* Authentication events
* Controller Manager activity
* Scheduler activity

This provides operational visibility into control-plane activity without exposing the worker nodes directly to the public internet.

## Security controls

Security is implemented across the AWS infrastructure and Kubernetes layers.

### AWS layer

* VPC network segmentation
* Private subnets for EKS worker nodes
* Security Group controls
* IAM roles for EKS resources
* Separate IAM roles for the EKS control plane and worker nodes
* NAT-based private subnet egress

### Kubernetes layer

* Dedicated application namespace
* Dedicated ServiceAccount
* NetworkPolicy
* Resource requests and limits
* Readiness and liveness probes
* Internal ClusterIP service
* ConfigMap-based application configuration

### Monitoring layer

* EKS control-plane logging
* Kubernetes audit logging
* CloudWatch log retention

## Engineering decisions

### Private worker subnets

EKS worker nodes are placed in private subnets rather than being directly exposed to the public internet.

Outbound connectivity is provided through the NAT Gateway.

This separates the worker fleet from direct inbound internet traffic while maintaining the connectivity required for normal cluster operations.

### Managed node group

The platform uses an EKS managed node group to reduce the operational overhead of maintaining the worker fleet while retaining control over node capacity and instance types.

### Kubernetes NetworkPolicy

AWS networking controls operate at the VPC and Security Group layers.

The Kubernetes NetworkPolicy provides an additional layer of workload-level traffic control inside the cluster.

### Resource requests and limits

Explicit resource requirements make workload scheduling more predictable and reduce the risk of a single workload consuming unrestricted node resources.

### Health probes

Readiness and liveness probes allow Kubernetes to distinguish between a running container and a workload that is ready to receive traffic.

## Project status

The development environment has been provisioned and validated successfully.

Current state:

* Terraform infrastructure deployed
* EKS cluster operational
* Managed worker nodes operational
* Kubernetes workload deployed
* Internal service connectivity verified
* NetworkPolicy applied
* EKS control-plane logging enabled
* CloudWatch logging configured
* Terraform plan validated
* Repository synchronized with GitHub

## Repository structure

```text
enterprise-cloud-security-platform/
├── .github/
├── diagrams/
├── docs/
├── images/
├── kubernetes/
├── lambda/
├── scripts/
├── terraform/
│   ├── bootstrap/
│   ├── environments/
│   └── modules/
├── .gitignore
└── README.md
```

## Future improvements

Potential future iterations include:

* Additional application workloads
* Ingress and external load balancing
* Autoscaling
* CI/CD deployment automation
* Expanded observability
* Additional Kubernetes security policies
* Automated infrastructure testing
* Production environment configuration

These improvements are outside the scope of the current implementation.

## Project focus

The project focuses on practical infrastructure engineering rather than a single AWS service.

It demonstrates how Terraform, AWS networking, Amazon EKS, Kubernetes workload configuration, IAM, security controls, and CloudWatch logging can be combined into a structured cloud platform.

The infrastructure is modular and can be extended with additional environments and workloads without restructuring the core Terraform modules.
