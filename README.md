# Terraform AWS ECS Infrastructure

## Overview

This repository provides Terraform configurations for deploying a production-grade AWS infrastructure. The setup includes containerized application deployment using AWS ECS Fargate, comprehensive networking, security configurations, and monitoring solutions.

## Architecture Components

### State Management

- **Backend Configuration**
  - S3 bucket for state storage
  - DynamoDB table for state locking
  - Encryption enabled for security
  - Versioning support for state history

### Networking Infrastructure

- **VPC Configuration**
  - Custom VPC with configurable CIDR block
  - Public and private subnets across multiple AZs
  - NAT gateways in each AZ for private subnet internet access
  - Internet Gateway for public subnet access
  - Route tables for traffic management

### Container Orchestration (ECS)

- **Cluster Setup**
  - ECS cluster using Fargate and Fargate Spot
  - Container Insights enabled for enhanced monitoring
  - Task definitions with configurable resources
  - Service auto-scaling capabilities

### Security Configurations

- **Security Groups**
  - ALB security group with HTTP/HTTPS ingress
  - ECS tasks security group with ALB-only access
  - Egress rules for container internet access
- **Network ACLs**
  - Subnet-level traffic control
  - Additional security layer beyond security groups

### Monitoring and Alerting

- **CloudWatch Integration**
  - Log groups for ECS containers with 30-day retention
  - CPU utilization alarms (threshold: 80%)
  - Memory utilization monitoring
  - Container insights metrics
- **SNS Notifications**
  - Alert topics for resource monitoring
  - Email subscription support
  - Customizable notification settings

## Project Structure

```
.
├── main.tf           # Provider and backend configuration
├── variables.tf      # Input variables
├── networking.tf     # VPC and subnet configuration
├── security.tf       # Security groups
├── ecs.tf           # ECS cluster setup
├── monitoring.tf     # CloudWatch and SNS
├── outputs.tf        # Output definitions
├── versions.tf       # Version constraints
└── terraform.tfvars  # Variable values
```

## Prerequisites

### Required Tools

1. **Terraform** (>= 1.0)

   - Installation guide: [Terraform Downloads](https://www.terraform.io/downloads.html)
   - Install commands:
     ```bash
     # MacOS
     brew install terraform
     # Windows
     choco install terraform
     ```
   - Verify installation: `terraform version`

2. **AWS CLI**
   - Installation guide: [AWS CLI Installation](https://aws.amazon.com/cli/)
   - Install commands:
     ```bash
     # MacOS
     brew install awscli
     # Windows
     choco install awscli
     ```
   - Configuration:
     ```bash
     aws configure
     # Enter AWS Access Key ID
     # Enter AWS Secret Access Key
     # Enter Default region (us-west-2)
     # Enter Default output format (json)
     ```

### Documentation

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/index.html)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### AWS Permissions

Required IAM permissions for deployment:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "vpc:*",
        "ecs:*",
        "cloudwatch:*",
        "s3:*",
        "dynamodb:*",
        "ec2:*",
        "elasticloadbalancing:*",
        "logs:*",
        "sns:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Backend Setup

1. Create S3 bucket:

```bash
aws s3api create-bucket \
    --bucket terraform-state-bucket \
    --region us-west-2 \
    --create-bucket-configuration LocationConstraint=us-west-2
```

2. Enable bucket versioning:

```bash
aws s3api put-bucket-versioning \
    --bucket terraform-state-bucket \
    --versioning-configuration Status=Enabled
```

3. Create DynamoDB table:

```bash
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
```

## Deployment Guide

### 1. Repository Setup

```bash
# Clone repository
git clone https://github.com/Reeteshrajesh/terraform.git
cd terraform

# Create necessary files
touch main.tf variables.tf networking.tf security.tf ecs.tf monitoring.tf outputs.tf versions.tf
```

### 2. Configuration

Create `terraform.tfvars`:

```hcl
aws_region   = "us-west-2"
environment  = "prod"
project_name = "my-project"
vpc_cidr     = "10.0.0.0/16"
azs          = ["us-west-2a", "us-west-2b", "us-west-2c"]
```

### 3. Infrastructure Deployment

```bash
# Initialize Terraform
terraform init

# Validate configurations
terraform validate

# Plan deployment
terraform plan -out=tfplan

# Apply changes
terraform apply tfplan
```

### 4. Post-Deployment Verification

```bash
# Verify successful deployment
terraform output

# Check VPC creation
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=${var.project_name}-vpc"

# Verify ECS cluster
aws ecs describe-clusters --clusters ${var.project_name}-cluster

# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=${var.project_name}*"
```

### 5. Configure Monitoring

1. Set up email notifications:

```bash
aws sns subscribe \
    --topic-arn <output_sns_topic_arn> \
    --protocol email \
    --notification-endpoint your@email.com
```

2. Verify CloudWatch logs:

```bash
aws logs describe-log-groups \
    --log-group-name-prefix /ecs/<project_name>
```

### 6. Application Deployment Steps

1. **Container Registry**

```bash
aws ecr create-repository \
    --repository-name <app-name> \
    --image-scanning-configuration scanOnPush=true
```

2. **Build and Push Image**

```bash
docker build -t <app-name> .
aws ecr get-login-password | docker login --username AWS --password-stdin <ecr-url>
docker tag <app-name>:latest <ecr-url>/<app-name>:latest
docker push <ecr-url>/<app-name>:latest
```

3. **Deploy ECS Service**
   - Create task definition
   - Configure service with ALB
   - Set up auto-scaling rules

## Infrastructure Outputs

- `vpc_id`: VPC identifier
- `private_subnet_ids`: Private subnet IDs
- `public_subnet_ids`: Public subnet IDs
- `ecs_cluster_name`: ECS cluster name
- `alb_dns_name`: ALB DNS endpoint

View outputs:

```bash
# View all outputs
terraform output

# Get specific output
terraform output vpc_id
terraform output private_subnet_ids
```

## Maintenance and Troubleshooting

### Common Issues

1. **State Lock Issues**

```bash
# Force unlock if needed
terraform force-unlock <lock-id>
```

2. **Permission Errors**

   - Verify AWS credentials
   - Check IAM policy attachments
   - Validate resource policies

3. **Resource Creation Failures**
   - Check VPC limits
   - Verify subnet CIDR availability
   - Monitor CloudWatch logs

### Cleanup

Remove infrastructure:

```bash
terraform plan -destroy -out=tfplan
terraform apply tfplan

# Verify cleanup
aws ecs list-clusters
aws ec2 describe-vpcs
```

## Security Considerations

1. Enable VPC Flow Logs
2. Implement AWS WAF with ALB
3. Use AWS Secrets Manager for sensitive data
4. Enable encryption at rest
5. Implement proper IAM roles

## Cost Optimization

- Use Fargate Spot for non-critical workloads
- Implement auto-scaling based on metrics
- Monitor and cleanup unused resources
- Use Cost Explorer for tracking

## Future Enhancements

1. Add WAF integration
2. Implement backup strategies
3. Add cross-region redundancy
4. Enhance monitoring dashboards
5. Implement CI/CD pipelines

## Author

- **Reetesh Kumar**
  - LinkedIn: [Reetesh Kumar](https://www.linkedin.com/in/reetesh-kumar-850807255/)
  - GitHub: [Reetesh Kumar](https://github.com/Reeteshrajesh)
  - Email: uttamreetesh@gmail.com

## Support and Contact

- GitHub Issues: [Create New Issue](https://github.com/Reeteshrajesh/terraform/issues)
- Documentation of project: [Project details](https://github.com/Reeteshrajesh/terraform/blob/main/README.md)
- Medium: [terraform project](https://medium.com/@uttamreetesh)

## Contributing

1. Fork repository
2. Create feature branch
3. Submit pull request
4. Follow coding standards

## License

MIT License - See LICENSE file for details
