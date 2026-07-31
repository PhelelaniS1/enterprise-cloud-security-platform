\# Enterprise Cloud Security Platform on AWS



\## Overview



This project is a Terraform-managed AWS platform built around Amazon EKS. It provisions the underlying network, compute, access controls, monitoring, and Kubernetes workload required to run a small production-style platform environment.



The project was built to demonstrate practical cloud and platform engineering skills across AWS, Terraform, Kubernetes, and infrastructure operations.



The current environment runs in `af-south-1` and consists of an Amazon VPC, private and public subnets, NAT connectivity, an Amazon EKS cluster, a managed node group, and a Kubernetes application deployed into a dedicated namespace.



\## Architecture



```text

&#x20;                        AWS

&#x20;                         │

&#x20;                   ┌─────▼─────┐

&#x20;                   │    VPC    │

&#x20;                   │ 10.0.0.0/16

&#x20;                   └─────┬─────┘

&#x20;                         │

&#x20;            ┌────────────┴────────────┐

&#x20;            │                         │

&#x20;     Public Subnets             Private Subnets

&#x20;            │                         │

&#x20;     ┌──────▼──────┐          ┌───────▼────────┐

&#x20;     │ NAT Gateway │          │   EKS Cluster  │

&#x20;     └──────┬──────┘          │                │

&#x20;            │                 │ Managed Nodes  │

&#x20;            └────────────────►│                │

&#x20;                              └───────┬────────┘

&#x20;                                      │

&#x20;                               Kubernetes

&#x20;                                      │

&#x20;                             ┌────────▼────────┐

&#x20;                             │    platform     │

&#x20;                             │    namespace    │

&#x20;                             └────────┬────────┘

&#x20;                                      │

&#x20;                             ┌────────▼────────┐

&#x20;                             │  platform-api   │

&#x20;                             │   Deployment    │

&#x20;                             │    2 replicas   │

&#x20;                             └────────┬────────┘

&#x20;                                      │

&#x20;                             ┌────────▼────────┐

&#x20;                             │    ClusterIP     │

&#x20;                             │     Service      │

&#x20;                             └─────────────────┘



&#x20;                   EKS Control Plane

&#x20;                         │

&#x20;                         ▼

&#x20;                   CloudWatch Logs

```



\## What was built



\### AWS infrastructure



The infrastructure is provisioned through Terraform using reusable modules.



The environment includes:



\* Amazon VPC

\* Public and private subnets across two availability zones

\* Internet Gateway

\* NAT Gateway

\* Public and private route tables

\* Route table associations

\* Security Group

\* Amazon EKS cluster

\* EKS managed node group

\* IAM roles and required AWS-managed policies

\* CloudWatch log groups for EKS logging



\### Amazon EKS



The development environment runs an Amazon EKS cluster with:



\* Kubernetes version: `1.35`

\* Cluster status: `ACTIVE`

\* Managed node group

\* Desired capacity: `2`

\* Minimum capacity: `2`

\* Maximum capacity: `3`

\* Instance type: `t3.medium`

\* Nodes deployed into the private networking layer



The cluster control plane has logging enabled for:



\* API server

\* Audit

\* Authenticator

\* Controller Manager

\* Scheduler



EKS control-plane logs are delivered to CloudWatch with a 30-day retention period.



\## Kubernetes workload



The application is deployed into a dedicated `platform` namespace.



```text

platform/

├── ConfigMap

├── ServiceAccount

├── NetworkPolicy

├── Deployment

└── ClusterIP Service

```



\### Deployment



`platform-api` runs two replicas using the `nginx:1.27-alpine` container image.



The deployment includes:



\* 2 replicas

\* RollingUpdate deployment strategy

\* CPU and memory requests

\* CPU and memory limits

\* Readiness probe

\* Liveness probe

\* ConfigMap-based environment configuration



The configured application values are:



```text

APP\_ENV=dev

APP\_NAME=enterprise-cloud-security-platform

LOG\_LEVEL=INFO

```



\### Service



The application is exposed internally through a Kubernetes `ClusterIP` service.



```text

Service:      platform-api

Type:         ClusterIP

Port:         80

Target Port:  80

```



The service resolves to the application pods running in the cluster.



\## Kubernetes network control



A Kubernetes NetworkPolicy is applied to the `platform-api` pods.



The policy controls ingress traffic to port `80/TCP` and permits traffic from workloads in the `platform` namespace.



This provides workload-level network segmentation in addition to the AWS networking and Security Group controls.



\## Terraform structure



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

&#x20;   ├── eks/

&#x20;   ├── monitoring/

&#x20;   ├── networking/

&#x20;   └── security/

```



\### Terraform modules



\#### Networking



Responsible for the underlying VPC networking:



\* VPC

\* Subnets

\* Internet Gateway

\* NAT Gateway

\* Route tables

\* Route associations



\#### EKS



Responsible for the Kubernetes control plane and managed worker nodes:



\* EKS cluster

\* Cluster IAM role

\* Node IAM role

\* Managed node group

\* Required IAM policy attachments



\#### Security



Responsible for AWS-level network access controls, including the platform Security Group.



\#### Monitoring



Responsible for CloudWatch logging associated with the platform and EKS cluster.



\## Infrastructure state



Terraform state is managed separately from the application infrastructure configuration through the project's bootstrap and environment configuration.



The repository does not commit Terraform state files.



\## Deployment



\### Prerequisites



The environment requires:



\* AWS CLI

\* Terraform

\* kubectl

\* An AWS identity with permissions to provision the required infrastructure

\* An AWS region configured for the deployment



The project was deployed in:



```text

af-south-1

```



\### Initialize Terraform



From the development environment:



```powershell

cd terraform\\environments\\dev



terraform init

```



\### Review the infrastructure



```powershell

terraform plan

```



The final validation returned:



```text

No changes. Your infrastructure matches the configuration.

```



\### Apply the infrastructure



```powershell

terraform apply

```



\### Configure kubectl



```powershell

aws eks update-kubeconfig `

&#x20; --region af-south-1 `

&#x20; --name enterprise-cloud-security-platform-dev-eks

```



Verify the nodes:



```powershell

kubectl get nodes

```



\### Deploy the Kubernetes resources



```powershell

kubectl create namespace platform

```



Apply the application configuration:



```powershell

kubectl apply -f .\\platform-config.yaml

kubectl apply -f .\\platform-serviceaccount.yaml

kubectl apply -f .\\platform-networkpolicy.yaml

kubectl apply -f .\\platform-app.yaml

```



Check the deployment:



```powershell

kubectl rollout status deployment/platform-api -n platform

```



\## Validation



The deployed environment was validated at both the AWS and Kubernetes layers.



\### EKS cluster



```text

Name:     enterprise-cloud-security-platform-dev-eks

Status:   ACTIVE

Version:  1.35

```



\### Node group



```text

Status:          ACTIVE

Desired:         2

Minimum:         2

Maximum:         3

Instance type:   t3.medium

```



\### Kubernetes nodes



Both worker nodes reported `Ready`.



```text

NAME                                        STATUS

ip-10-0-11-5.af-south-1.compute.internal   Ready

ip-10-0-12-52.af-south-1.compute.internal  Ready

```



\### Application pods



```text

NAME                           READY   STATUS

platform-api-745bbd545-22btq   1/1     Running

platform-api-745bbd545-zjn4p   1/1     Running

```



\### Service



```text

NAME           TYPE        CLUSTER-IP     PORT(S)

platform-api   ClusterIP   172.20.31.15   80/TCP

```



\### NetworkPolicy



```text

NAME           POD-SELECTOR

platform-api   app=platform-api

```



The policy permits ingress to port `80/TCP` from the `platform` namespace.



\### Service connectivity



Connectivity was tested from a temporary pod inside the Kubernetes cluster:



```powershell

kubectl run test-client `

&#x20; -n platform `

&#x20; --image=curlimages/curl:8.12.1 `

&#x20; --rm -it `

&#x20; --restart=Never `

&#x20; -- curl -I http://platform-api

```



The service returned:



```text

HTTP/1.1 200 OK

```



This confirmed that the Kubernetes Service correctly routes traffic to the application pods.



\### Terraform validation



The final Terraform plan completed successfully:



```text

No changes. Your infrastructure matches the configuration.



Terraform has compared your real infrastructure against your configuration

and found no differences, so no changes are needed.

```



\## Monitoring and logging



EKS control-plane logging is enabled for:



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



The log group is configured with:



```text

Retention: 30 days

Class:     STANDARD

```



This provides centralized visibility into EKS control-plane activity.



\## Security controls



Security is implemented at multiple layers rather than relying on a single control.



\### AWS layer



\* VPC network segmentation

\* Private subnets for EKS worker nodes

\* Security Group controls

\* IAM roles for EKS resources

\* IAM policy separation between cluster and worker nodes

\* NAT-based private subnet egress



\### Kubernetes layer



\* Dedicated application namespace

\* Dedicated ServiceAccount

\* NetworkPolicy

\* Resource requests and limits

\* Readiness and liveness probes

\* Internal ClusterIP service

\* ConfigMap-based application configuration



\### Monitoring layer



\* EKS control-plane logging

\* Audit logging

\* CloudWatch log retention



\## Engineering decisions



\### Why private subnets?



Worker nodes are placed in private subnets rather than directly exposing them to the public internet. Outbound connectivity is provided through the NAT Gateway.



\### Why use a managed node group?



EKS managed node groups reduce the operational overhead associated with provisioning and maintaining the worker fleet while still allowing control over capacity and instance types.



\### Why use Kubernetes NetworkPolicy?



AWS networking controls operate at the VPC and Security Group layers. NetworkPolicy adds another layer of control inside the Kubernetes cluster, allowing workload-to-workload traffic rules to be defined independently.



\### Why use resource requests and limits?



Explicit resource requirements make workload scheduling more predictable and prevent a single workload from consuming unrestricted node resources.



\### Why use health probes?



Readiness and liveness probes allow Kubernetes to distinguish between a running container and a workload that is actually ready to receive traffic.



\## Project status



The development environment has been provisioned and validated successfully.



Current state:



\* Terraform infrastructure deployed

\* EKS cluster operational

\* Managed worker nodes operational

\* Kubernetes workload deployed

\* Internal service connectivity verified

\* NetworkPolicy applied

\* EKS control-plane logging enabled

\* CloudWatch logging configured

\* Terraform plan validated

\* Repository synchronized with GitHub



\## Repository



The project source code and infrastructure configuration are maintained in this repository.



The implementation is intentionally modular so that additional environments and workloads can be introduced without restructuring the core Terraform modules.



\## Future improvements



Possible future iterations could include:



\* Additional application workloads

\* Ingress and external load balancing

\* Autoscaling

\* CI/CD deployment automation

\* Expanded observability

\* Additional Kubernetes security policies

\* Automated infrastructure testing

\* Production environment configuration



These are intentionally outside the current implementation scope.



