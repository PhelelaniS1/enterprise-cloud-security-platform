\# Enterprise Cloud Security Platform on AWS



\## Overview



This project is a Terraform-managed AWS platform built around Amazon EKS. It provisions the underlying network, compute, access controls, monitoring, and Kubernetes workload required to run a small production-style platform environment.



The project was built to demonstrate practical cloud and platform engineering skills across AWS, Terraform, Kubernetes, and infrastructure operations.



The current environment runs in `af-south-1` and consists of an Amazon VPC, public and private subnets, NAT connectivity, an Amazon EKS cluster, a managed node group, and a Kubernetes application deployed into a dedicated namespace.



\## Architecture



```text

&#x20;                               AWS

&#x20;                                │

&#x20;                        ┌───────▼───────┐

&#x20;                        │      VPC      │

&#x20;                        │   10.0.0.0/16 │

&#x20;                        └───────┬───────┘

&#x20;                                │

&#x20;               ┌────────────────┴────────────────┐

&#x20;               │                                 │

&#x20;       Public Subnets                     Private Subnets

&#x20;               │                                 │

&#x20;       ┌───────▼───────┐               ┌────────▼────────┐

&#x20;       │  NAT Gateway  │──────────────►│   EKS Cluster   │

&#x20;       └───────────────┘               │                 │

&#x20;                                       │ Managed Nodes   │

&#x20;                                       └────────┬────────┘

&#x20;                                                │

&#x20;                                         Kubernetes

&#x20;                                                │

&#x20;                                     ┌──────────▼──────────┐

&#x20;                                     │  platform namespace │

&#x20;                                     └──────────┬──────────┘

&#x20;                                                │

&#x20;                                     ┌──────────▼──────────┐

&#x20;                                     │    platform-api      │

&#x20;                                     │     Deployment       │

&#x20;                                     │      2 replicas      │

&#x20;                                     └──────────┬──────────┘

&#x20;                                                │

&#x20;                                     ┌──────────▼──────────┐

&#x20;                                     │     ClusterIP        │

&#x20;                                     │       Service        │

&#x20;                                     └──────────────────────┘



&#x20;                        EKS Control Plane

&#x20;                                │

&#x20;                                ▼

&#x20;                        CloudWatch Logs

