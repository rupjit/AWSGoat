```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}

variable "existing_ebs_volume_id" {
  description = "Existing EBS volume ID to attach"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

locals {
  common_tags = {
    Environment          = "production"
    Application          = "web-portal"
    Owner                = "it-operations-team"
    CostCenter           = "IT-OPS-001"
    Project              = "digital-transformation"
    ServiceLevel         = "critical"
    BackupRequired       = "true"
    MonitoringEnabled    = "true"
    PatchGroup           = "monthly"
    ComplianceRequired   = "sox-gdpr"
    DataClassification   = "confidential"
    BusinessUnit         = "healthcare-technology"
    MaintenanceWindow    = "sunday-02:00-06:00"
    DisasterRecovery     = "enabled"
    SecurityGroup        = "dmz-web-tier"
    AutoScaling          = "enabled"
    LogRetention         = "90-days"
    IncidentPriority     = "high"
    ServiceDesk          = "servicenow-integration"
    ChangeManagement     = "required"
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "web_portal_sg" {
  name        = "web-portal-dmz-sg"
  description = "Security group for web portal EC2 instance in DMZ"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from management network"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "web-portal-dmz-security-group"
    }
  )
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "web_portal_role" {
  name = "web-portal-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "web-portal-ec2-role"
    }
  )
}

# IAM Policy for CloudWatch and SSM
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.web_portal_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.web_portal_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "web_portal_profile" {
  name = "web-portal-instance-profile"
  role = aws_iam_role.web_portal_role.name

  tags = merge(
    local.common_tags,
    {
      Name = "web-portal-instance-profile"
    }
  )
}

# EC2 Instance
resource "aws_instance" "web_portal" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.web_portal_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.web_portal_profile.name

  monitoring = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = false

    tags = merge(
      local.common_tags,
      {
        Name = "web-portal-root-volume"
      }
    )
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    # Install CloudWatch agent
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
    
    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCONFIG'
    {
      "metrics": {
        "namespace": "WebPortal/EC2",
        "metrics_collected": {
          "cpu": {
            "measurement": [{"name": "cpu_usage_idle", "rename": "CPU_IDLE", "unit": "Percent"}],
            "metrics_collection_interval": 60
          },
          "disk": {
            "measurement": [{"name": "used_percent", "rename": "DISK_USED", "unit": "Percent"}],
            "metrics_collection_interval": 60,
            "resources": ["*"]
          },
          "mem": {
            "measurement": [{"name": "mem_used_percent", "rename": "MEM_USED", "unit": "Percent"}],
            "metrics_collection_interval": 60
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/aws/ec2/web-portal/system",
                "log_stream_name": "{instance_id}",
                "retention_in_days": 90
              }
            ]
          }