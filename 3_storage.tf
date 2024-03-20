# Resource: aws_efs_file_system
# Creates an Elastic File System (EFS), providing a scalable, elastic, cloud-native file system for Linux-based workloads.
# EFS is ideal for use cases such as shared storage for Kubernetes pods, big data and analytics applications, or as a file server.
# It automatically scales without needing to provision storage or throughput, offering a simple interface that allows you to create and configure file systems quickly.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system

resource "aws_efs_file_system" "efs_eks" {
  kms_key_id = aws_kms_key.efs_cbs.arn
  encrypted = true
  tags = {
    Name        = join("-",[local.prefix,"efs",var.appname,var.environment])
    Environment = var.environment
  }
}

# Resource: aws_security_group
# Defines a security group for controlling access to resources within your VPC. It acts as a virtual firewall.
# Security groups are crucial for defining inbound and outbound traffic rules to secure your resources.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "amazon_efs_security_group" {
  description = "Amazon Elastic FS Security Group"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "Access from TCP/2049 (NFS)"
    security_groups = data.aws_launch_template.eks_nodes_lt.network_interfaces.0.security_groups
    protocol        = "TCP"
    from_port       = 2049
    to_port         = 2049
  }

  tags = {
    Name = join("-",[local.prefix,"sg",var.appname,var.environment,"efs"])
  }
}

# Resource: aws_efs_mount_target
# Creates a mount target for an Elastic File System (EFS), allowing EC2 instances or Kubernetes pods on EKS nodes to mount the file system.
# Mount targets are essential for connecting your EFS file system to EC2 instances or EKS clusters within a specific VPC.
# Each mount target is associated with one subnet, and you need one mount target in each subnet that needs access to the EFS file system.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target

resource "aws_efs_mount_target" "efs_eks_mount_1" {
  file_system_id  = aws_efs_file_system.efs_eks.id
  subnet_id       = aws_subnet.priv_subnet["efs-a"].id
  security_groups = [aws_security_group.amazon_efs_security_group.id]
}

# Resource: aws_efs_mount_target
# Creates a mount target for an Elastic File System (EFS), allowing EC2 instances or Kubernetes pods on EKS nodes to mount the file system.
# Mount targets are essential for connecting your EFS file system to EC2 instances or EKS clusters within a specific VPC.
# Each mount target is associated with one subnet, and you need one mount target in each subnet that needs access to the EFS file system.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target

resource "aws_efs_mount_target" "efs_eks_mount_2" {
  file_system_id  = aws_efs_file_system.efs_eks.id
  subnet_id       = aws_subnet.priv_subnet["efs-b"].id
  security_groups = [aws_security_group.amazon_efs_security_group.id]
}

# Resource: aws_efs_mount_target
# Creates a mount target for an Elastic File System (EFS), allowing EC2 instances or Kubernetes pods on EKS nodes to mount the file system.
# Mount targets are essential for connecting your EFS file system to EC2 instances or EKS clusters within a specific VPC.
# Each mount target is associated with one subnet, and you need one mount target in each subnet that needs access to the EFS file system.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target

resource "aws_efs_mount_target" "efs_eks_mount_3" {
  file_system_id  = aws_efs_file_system.efs_eks.id
  subnet_id       = aws_subnet.priv_subnet["efs-c"].id
  security_groups = [aws_security_group.amazon_efs_security_group.id]
}


# Resource: aws_s3_bucket
# Creates an Amazon S3 bucket for object storage. S3 buckets can be used for a wide range of purposes,
# including storing images, videos, log files, backup data, and other blob storage needs.
# This example sets up a bucket intended for use with an Amazon EKS cluster, which can be used for storing application logs, backup data, or other artifacts.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket

resource "aws_s3_bucket" "s3_eks_bucket" {
  #checkov:skip=CKV_AWS_18:Content for this bucket has not been defined yet
  #checkov:skip=CKV2_AWS_61:Content for this bucket has not been defined yet
  #checkov:skip=CKV2_AWS_62:Content for this bucket has not been defined yet
  #checkov:skip=CKV_AWS_21:Content for this bucket has not been defined yet
  #checkov:skip=CKV_AWS_144:Content for dev environment is not cross-region replicated
  bucket        = join("-",[local.prefix,"s3",var.appname,var.environment, "bucket"])
  force_destroy = true

  tags = {
    Name        = join("-",[local.prefix,"s3",var.appname,var.environment, "bucket"])
    Environment = var.environment
  }
}

# Resource: aws_s3_bucket_public_access_block
# Applies public access block configurations to an S3 bucket to secure the bucket by explicitly denying public access, regardless of the bucket's ACL or object-level permissions.
# This is crucial for preventing accidental data exposure and ensuring that your S3 data is only accessible through intended means and to authorized users or services.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block

resource "aws_s3_bucket_public_access_block" "bpa_s3" {
  bucket                  = aws_s3_bucket.s3_eks_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Resource: aws_s3_bucket_server_side_encryption_configuration
# Applies server-side encryption settings to an S3 bucket, ensuring that all objects are encrypted at rest within the bucket.
# Server-side encryption is a critical security measure for protecting your data from unauthorized access and ensuring compliance with data protection regulations.
# This configuration uses AWS-managed keys (SSE-S3) for encryption, but you can also specify AWS KMS keys (SSE-KMS) for additional control and auditability.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_eks_bucket" {
  bucket = aws_s3_bucket.s3_eks_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      #kms_master_key_id = "arn:aws:kms:us-east-1:502318466105:key/a2b8ee1a-bdfc-4548-b7ef-1777f830813a"
      kms_master_key_id = aws_kms_key.s3_cbs.arn
    }
  }
}

# Resource: aws_s3_bucket_policy
# Applies a bucket policy to enforce SSL (HTTPS) for all requests to the S3 bucket.
# Enforcing SSL ensures that all data in transit to and from the S3 bucket is encrypted, 
# providing an additional layer of security for sensitive data.
# This is particularly important for applications that store or process personal data, financial information,
# or any other type of sensitive information that requires secure transmission.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy

resource "aws_s3_bucket_policy" "enforce_ssl_policy_s3" {
  bucket = aws_s3_bucket.s3_eks_bucket.id
  policy = data.aws_iam_policy_document.enforce_ssl_policy.json
}

# Data source: aws_iam_policy_document
# Generates an IAM policy document in JSON format that enforces SSL (HTTPS) for all requests to an S3 bucket.
# This IAM policy document is typically used in conjunction with an S3 bucket policy to enhance security by ensuring that data in transit is encrypted.
# The use of SSL prevents man-in-the-middle attacks and eavesdropping on data as it moves between clients and the S3 bucket.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

data "aws_iam_policy_document" "enforce_ssl_policy" {
  statement {
    sid = "RequireSecureTransport"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.s3_eks_bucket.arn,
      "${aws_s3_bucket.s3_eks_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}
