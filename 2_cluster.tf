
# Resource: aws_eks_cluster
# Creates an Amazon Elastic Kubernetes Service (EKS) cluster, which provides a managed Kubernetes service allowing you to run and scale containerized applications using Kubernetes on AWS.
# EKS clusters are essential for orchestrating containers, managing deployments, and scaling applications in a secure and efficient manner.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster

resource "aws_eks_cluster" "eks_cluster" {
  #checkov:skip=CKV_AWS_339:The checkov code is not updated to check 1.28 is the newest available version
  name     = join("-",[local.prefix,var.environment,var.appname,"eks-cluster"])
  version  = var.k8s_version                   # Specify the Kubernetes version for your cluster. Check AWS EKS documentation for the supported versions.
  role_arn = aws_iam_role.eks_cluster_role.arn #Ensure this is the ARN of an IAM role with EKS permissions
  vpc_config {
    security_group_ids = [
      aws_security_group.eks_control_plane_security_group.id
    ]
    subnet_ids = [
      aws_subnet.priv_subnet["eks-a"].id,
      aws_subnet.priv_subnet["eks-b"].id,
      aws_subnet.priv_subnet["eks-c"].id
    ]
    endpoint_public_access  = false
    endpoint_private_access = true
  }
  kubernetes_network_config {
    ip_family         = "ipv4"
    service_ipv4_cidr = "172.20.0.0/16"
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_cmk.arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = ["audit", "api", "authenticator", "scheduler", "controllerManager"]
  tags = {
    Name = join("",[join("-",[local.prefix,var.environment,var.appname,"eks-cluster"]),"/EKSCluster"])
  }
}

# Resource: aws_security_group
# Defines a security group for controlling access to resources within your VPC. It acts as a virtual firewall.
# Security groups are crucial for defining inbound and outbound traffic rules to secure your resources.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "eks_control_plane_security_group" {
  name        = join("-",[local.prefix,"sg",var.environment,var.appname,"eks"])
  description = "Cluster external communication"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Private management access"
    cidr_blocks = ["10.209.15.0/24"]
    protocol    = "TCP"
    from_port   = 443
    to_port     = 443
  }
  tags = {
    Name = join("-",[local.prefix,"sg",var.environment,var.appname,"eks"])
  }
}

# Resource: aws_eks_node_group
# Creates a managed node group for an Amazon EKS cluster, automating the provisioning and lifecycle management of the nodes (instances EC2) for EKS.
# Managed node groups make it easy to manage, scale, and upgrade groups of EC2 instances as worker nodes in your EKS clusters.
# This example configures a node group with specified instance types, scaling settings, and integrates with an existing EKS cluster and IAM roles for nodes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = join("-",[local.prefix,"eks",var.environment,var.appname,"nodegroup"])
  instance_types  = [local.sizing[var.environment]["eks_node_size"]]
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids = [
    aws_subnet.iso_subnet["nodes-a"].id,
    aws_subnet.iso_subnet["nodes-b"].id,
    aws_subnet.iso_subnet["nodes-c"].id
  ]
  scaling_config {
    desired_size = local.sizing[var.environment]["eks_cluster_desired_size"]
    max_size     = local.sizing[var.environment]["eks_cluster_max_size"]
    min_size     = local.sizing[var.environment]["eks_cluster_min_size"]
  }

  update_config {
    max_unavailable = 1
  }
}


# Resource: aws_eks_addon
# Manages an EKS add-on for an Amazon EKS cluster
# This example configuresthe basic add-ons,for an EKS cluster.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon


resource "aws_eks_addon" "core_dns" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "PRESERVE"
  resolve_conflicts_on_create = "OVERWRITE"
}

# Resource: aws_eks_addon
# Manages an EKS add-on for an Amazon EKS cluster
# This example configuresthe basic add-ons,for an EKS cluster.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "PRESERVE"
  resolve_conflicts_on_create = "OVERWRITE"
}

# Resource: aws_eks_addon
# Manages an EKS add-on for an Amazon EKS cluster
# This example configuresthe basic add-ons,for an EKS cluster.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "PRESERVE"
  resolve_conflicts_on_create = "OVERWRITE"
}

# Data source: aws_autoscaling_group
# Retrieves information about a specified Auto Scaling group.
# This is particularly useful for integrating AWS services or third-party tools with your Auto Scaling groups,
# such as when you need to query for specific attributes or manage scaling policies dynamically.
# In the context of Amazon EKS, this data source can help manage or monitor the Auto Scaling groups used for EKS node groups.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/autoscaling_group

data "aws_autoscaling_group" "eks_nodes_asg" {
  name = aws_eks_node_group.eks_nodes.resources.0.autoscaling_groups.0.name
}

# Resource: aws_autoscaling_group_tag
# Manages an individual Autoscaling Group (ASG) tag. This resource should only be used 
# in cases where ASGs are created outside Terraform (e.g., ASGs implicitly created by EKS Node Groups).
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group_tag

resource "aws_autoscaling_group_tag" "name_tag" {
  autoscaling_group_name = aws_eks_node_group.eks_nodes.resources.0.autoscaling_groups.0.name

  tag {
    key   = "Name"
    value = join("-",[local.prefix,"eks",var.environment,var.appname,"node"])

    propagate_at_launch = true
  }
}

# Data source: aws_launch_template
# Retrieves information about a specified EC2 launch template.
# Launch templates define the configuration of EC2 instances, such as instance type, AMI, key pairs, security groups, and more.
# This is particularly useful for managing configurations of instances or Auto Scaling groups dynamically in infrastructure as code (IaC).
# In the context of Amazon EKS, this data source can help to fetch configuration details of launch templates used for EKS node groups, enabling consistent deployment and management of EKS nodes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/launch_template

data "aws_launch_template" "eks_nodes_lt" {
  name = data.aws_autoscaling_group.eks_nodes_asg.mixed_instances_policy.0.launch_template.0.launch_template_specification.0.launch_template_name
}


# Troubleshooting: Obtain information Related to Cluster for future use.
/*
output "eks_cluster_oidc" {
  value = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}
*/