```hcl
# ./generated/ec2/main.tf

resource "aws_instance" "web_portal" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.large"
  
  vpc_security_group_ids = [aws_security_group.web_portal.id]
  subnet_id              = data.aws_subnet.selected.id
  
  monitoring = true
  
  root_block_device {
    volume_type           = "gp3"
    volume_size           = 100
    encrypted             = true
    delete_on_termination = false
    
    tags = {
      Name                  = "web-portal-root-volume"
      Environment           = "production"
      Application           = "web-portal"
      Owner                 = "it-operations-team"
      CostCenter            = "IT-OPS-003"
      Project               = "digital-transformation"
      ServiceLevel          = "critical"
      BackupRequired        = "true"
      MonitoringEnabled     = "true"
      PatchGroup            = "monthly"
      ComplianceRequired    = "sox-gdpr"
      DataClassification    = "confidential"
      BusinessUnit          = "healthcare-technology"
      MaintenanceWindow     = "sunday-02:00-06:00"
      DisasterRecovery      = "enabled"
      SecurityGroup         = "dmz-web-tier"
      AutoScaling           = "enabled"
      LogRetention          = "90-days"
      IncidentPriority      = "high"
      ServiceDesk           = "servicenow-integration"
      ChangeManagement      = "required"
    }
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  
  tags = {
    Name                  = "web-portal-instance"
    Environment           = "production"
    Application           = "web-portal"
    Owner                 = "it-operations-team"
    CostCenter            = "IT-OPS-003"
    Project               = "digital-transformation"
    ServiceLevel          = "critical"
    BackupRequired        = "true"
    MonitoringEnabled     = "true"
    PatchGroup            = "monthly"
    ComplianceRequired    = "sox-gdpr"
    DataClassification    = "confidential"
    BusinessUnit          = "healthcare-technology"
    MaintenanceWindow     = "sunday-02:00-06:00"
    DisasterRecovery      = "enabled"
    SecurityGroup         = "dmz-web-tier"
    AutoScaling           = "enabled"
    LogRetention          = "90-days"
    IncidentPriority      = "high"
    ServiceDesk           = "servicenow-integration"
    ChangeManagement      = "required"
  }
}

resource "aws_security_group" "web_portal" {
  name        = "web-portal-sg"
  description = "Security group for web portal EC2 instances"
  vpc_id      = data.aws_vpc.selected.id
  
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name                  = "web-portal-sg"
    Environment           = "production"
    Application           = "web-portal"
    Owner                 = "it-operations-team"
    CostCenter            = "IT-OPS-003"
    Project               = "digital-transformation"
    ServiceLevel          = "critical"
    BackupRequired        = "true"
    MonitoringEnabled     = "true"
    PatchGroup            = "monthly"
    ComplianceRequired    = "sox-gdpr"
    DataClassification    = "confidential"
    BusinessUnit          = "healthcare-technology"
    MaintenanceWindow     = "sunday-02:00-06:00"
    DisasterRecovery      = "enabled"
    SecurityGroup         = "dmz-web-tier"
    AutoScaling           = "enabled"
    LogRetention          = "90-days"
    IncidentPriority      = "high"
    ServiceDesk           = "servicenow-integration"
    ChangeManagement      = "required"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "web-portal-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ec2 cpu utilization"
  
  dimensions = {
    InstanceId = aws_instance.web_portal.id
  }
  
  tags = {
    Name                  = "web-portal-cpu-alarm"
    Environment           = "production"
    Application           = "web-portal"
    Owner                 = "it-operations-team"
    CostCenter            = "IT-OPS-003"
    Project               = "digital-transformation"
    ServiceLevel          = "critical"
    BackupRequired        = "true"
    MonitoringEnabled     = "true"
    PatchGroup            = "monthly"
    ComplianceRequired    = "sox-gdpr"
    DataClassification    = "confidential"
    BusinessUnit          = "healthcare-technology"
    MaintenanceWindow     = "sunday-02:00-06:00"
    DisasterRecovery      = "enabled"
    SecurityGroup         = "dmz-web-tier"
    AutoScaling           = "enabled"
    LogRetention          = "90-days"
    IncidentPriority      = "high"
    ServiceDesk           = "servicenow-integration"
    ChangeManagement      = "required"
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "selected" {
  default = true
}

data "aws_subnet" "selected" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = data.aws_availability_zones.available.names[0]
}

data "aws_availability_zones" "available" {
  state = "available"
}
```