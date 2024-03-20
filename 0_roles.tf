# This file defines IAM roles/profiles needed for the AWS infrastructure.
# Purpose: The IAM roles are used to provide permissions that define what actions entities (users, user groups, and AWS resources) can perform on AWS resources.

# Resource: aws_iam_role
# This resource creates an IAM role that entities can assume under certain conditions.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

resource "aws_iam_role" "eks_cluster_role" {
  description = "This IAM Role is used for the EKS Cluster"
  name        = join("-",[local.prefix,local.project,"role",var.environment,var.appname,"eks","cluster"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "eks.amazonaws.com"
          ]
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
    "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  ]
}

# Resource: aws_iam_role
# This resource creates an IAM role that entities can assume under certain conditions.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

resource "aws_iam_role" "eks_node_role" {
  description = "This IAM Role is used for the EKS Cluster Node Members"
  name        = join("-",[local.prefix,local.project,"role",var.environment,var.appname,"ec2","nodes"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "ec2.amazonaws.com"
          ]
        }
        Action = [
          "sts:AssumeRole"
        ]
      }
    ]
  })
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
  ]
}

# Resource: aws_iam_instance_profile
# This resource is used to create an IAM instance profile which can be used to assign IAM roles to EC2 instances.
# The instance profile lets your EC2 instances use the permissions defined in the roles.
# For more information, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile

resource "aws_iam_instance_profile" "eks_nodes_instance_profile" {
  name = aws_iam_role.eks_node_role.name
  role = aws_iam_role.eks_node_role.name
}