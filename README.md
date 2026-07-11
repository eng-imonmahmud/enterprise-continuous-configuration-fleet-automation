# Enterprise Continuous Configuration & Fleet Automation Pipeline

![Status](https://img.shields.io/badge/Status-Completed-success)
![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4.svg?logo=terraform)
![AWS](https://img.shields.io/badge/AWS-Cloud-232F3E.svg?logo=amazon-aws)
![SSM](https://img.shields.io/badge/Systems_Manager-Managed-success)
![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Last Updated](https://img.shields.io/badge/Last_Updated-July_2026-informational)

**Author:** Imon Mahmud. 
IT SPECIALIST | CLOUD INFRASTRUCTURE & AI AUTOMATION ENGINEER

## Executive Summary
This repository contains the Infrastructure as Code (IaC) and automation scripts for an enterprise-grade Continuous Configuration platform. Leveraging AWS Systems Manager (SSM) and Terraform, this project provisions a strictly isolated EC2 fleet that adheres to a rigorous **Zero Trust Architecture**. The entire platform was designed, deployed, validated, and documented autonomously.

## Business Problem
Enterprise environments require strict compliance, zero public exposure, and continuous enforcement of configuration states across thousands of virtual machines. Traditional SSH-based management and public bastion hosts introduce significant security vectors and operational overhead.

## Solution
A fully automated, agent-based architecture where instances pull configuration from AWS Systems Manager.
- **No Inbound Network Access:** Security Groups have zero ingress rules.
- **No SSH or Bastion Hosts:** All terminal access and configuration happen securely via SSM Session Manager and Run Command.
- **Continuous Compliance:** SSM State Manager enforces the desired state (e.g., Nginx, CloudWatch Agent) automatically.

## Technology Stack
- **Provisioning:** Terraform (Modular Architecture)
- **Cloud Provider:** Amazon Web Services (AWS - eu-central-1)
- **Configuration Management:** AWS Systems Manager (SSM Parameter Store, Documents, State Manager)
- **Compute:** Amazon EC2 (AL2023)
- **Networking:** VPC, Private Subnets, VPC Interface & Gateway Endpoints

## Architecture Diagram
```mermaid
graph TD
    subgraph AWS Cloud [eu-central-1]
        subgraph VPC [Enterprise VPC]
            direction TB
            subgraph PrivateSubnet [Private Subnet]
                EC2[EC2 Fleet Node<br/>AL2023]
            end
            
            SSMEndpoint[SSM VPC Endpoints<br/>Interface]
            S3Endpoint[S3 Gateway Endpoint]
        end
        
        SSM[AWS Systems Manager]
        CW[Amazon CloudWatch]
        S3[Amazon S3<br/>Yum Repos]
        
        EC2 -->|HTTPS 443| SSMEndpoint
        EC2 -->|HTTPS 443| S3Endpoint
        SSMEndpoint --> SSM
        S3Endpoint --> S3
        EC2 -.->|Metrics| CW
    end
    
    classDef secure fill:#d4edda,stroke:#28a745,stroke-width:2px;
    class EC2 secure;
```

## Repository Structure
```text
├── .gitignore
├── README.md
├── SECURITY_AUDIT_REPORT.md
├── documents/
│   ├── install_cw_agent.yaml
│   └── install_nginx.yaml
├── scripts/
│   ├── verify_fleet.ps1
│   └── verify_fleet.sh
├── screenshots/
└── terraform/
    ├── main.tf
    ├── outputs.tf
    ├── providers.tf
    ├── variables.tf
    └── modules/
        ├── ec2/
        ├── iam/
        ├── ssm/
        └── vpc/
```

## Security Architecture & Zero Trust Design
1. **Private Subnets Only:** Resources are completely hidden from the public internet.
2. **Egress-Only Security Groups:** EC2 instances cannot accept any inbound connections, strictly enforcing a pull-based management model.
3. **VPC Endpoints (AWS PrivateLink):** Traffic to AWS Services (SSM, S3) never traverses the public internet.
4. **IAM Instance Profiles:** Least privilege policies (`AmazonSSMManagedInstanceCore`, `CloudWatchAgentServerPolicy`) are attached instead of long-lived access keys.

## Configuration Management Workflow
1. **SSM Parameter Store** securely holds configuration values and environmental metadata.
2. **SSM Documents** define the exact shell scripts required to install dependencies.
3. **SSM State Manager** runs associations on a schedule or instance boot, guaranteeing the node converges to the desired state without manual intervention.

## Validation & Testing
The `scripts/verify_fleet.ps1` runs post-deployment to ensure:
- Instance registers as `Online` in Systems Manager.
- State Manager Associations complete with `Success`.
- Nginx service is verified as running via SSM `AWS-RunShellScript`.

## Cost Optimization
- Eliminated NAT Gateways (saving ~$32/month) by utilizing S3 Gateway Endpoints (Free) and SSM Interface Endpoints, significantly reducing idle network costs while maintaining extreme security.

---

## Screenshot Gallery

### 1. Zero Trust EC2 & Networking
The instance runs entirely in a private subnet with no public IP and egress-only security rules.
![EC2 Instance](screenshots/screencapture-eu-central-1-console-aws-amazon-ec2-home-2026-07-11-12_30_59.png)
![Security Group](screenshots/screencapture-eu-central-1-console-aws-amazon-ec2-home-2026-07-11-12_31_46.png)
![VPC Subnets](screenshots/screencapture-eu-central-1-console-aws-amazon-vpcconsole-home-2026-07-11-12_33_42.png)
![VPC Endpoints](screenshots/screencapture-eu-central-1-console-aws-amazon-vpcconsole-home-2026-07-11-12_34_22.png)

### 2. Systems Manager Fleet Automation
AWS Systems Manager maintains total control over the private instance, managing configurations and states.
![Fleet Manager](screenshots/screencapture-eu-central-1-console-aws-amazon-systems-manager-fleet-manager-managed-nodes-i-0b70962c630565a58-general-2026-07-11-12_35_50.png)
![Parameter Store](screenshots/screencapture-eu-central-1-console-aws-amazon-systems-manager-parameters-2026-07-11-12_36_22.png)
![State Manager](screenshots/screencapture-eu-central-1-console-aws-amazon-systems-manager-state-manager-2026-07-11-12_37_46.png)

### 3. Additional AWS Components
![Architecture View](screenshots/screencapture-eu-central-1-console-aws-amazon-ec2-home-2026-07-11-12_32_39.png)
![Architecture View 2](screenshots/screencapture-eu-central-1-console-aws-amazon-ec2-home-2026-07-11-12_38_31.png)
![VPC View](screenshots/screencapture-eu-central-1-console-aws-amazon-vpcconsole-home-2026-07-11-12_33_21.png)
![VPC Endpoints View](screenshots/screencapture-eu-central-1-console-aws-amazon-vpcconsole-home-2026-07-11-12_35_06.png)

## Conclusion
This implementation proves the viability of highly secure, scalable, and fully automated cloud infrastructures. The architecture removes human-error vectors (like exposed SSH ports) and guarantees infrastructural compliance natively within AWS.
