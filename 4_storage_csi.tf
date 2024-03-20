# Data source: aws_iam_policy_document
# Generates an IAM policy document in JSON format that outlines the trust relationship for an IAM role.
# This example creates a trust policy for the Amazon EFS CSI driver, allowing it to assume an IAM role.
# The trust policy is a critical component when setting up IAM roles for Kubernetes service accounts, enabling
# the EFS CSI driver to interact securely with AWS resources.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

data "aws_iam_policy_document" "efs_csi_trust_policy" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_ip.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.eks_oidc_ip.arn), 3)}:aud"
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:efs-csi-*"]
      variable = "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.eks_oidc_ip.arn), 3)}:sub"
    }
  }
}

# Resource: aws_iam_role
# Creates an IAM role for the Amazon EFS CSI driver in an Amazon EKS cluster.
# This role grants permissions that allow the driver to interact with AWS resources, specifically Amazon EFS.
# It includes a trust relationship policy that enables the EKS service or EC2 instances to assume this role.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

# https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html
resource "aws_iam_role" "eks_efs_csi_role" {
  description        = "This IAM Role is used for the AWS EFS CSI Driver"
  name               = join("-",[local.prefix,local.project,"eks-role",var.appname,"efs-csi-driver"])
  assume_role_policy = data.aws_iam_policy_document.efs_csi_trust_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  ]
}


# Resource: aws_eks_addon
# Manages an EKS cluster addon like "vpc-cni", "kube-proxy", or "coredns".
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
# Note: Ensure the 'cluster_name' matches the name of your EKS cluster and 'addon_name' is replaced
# with a valid addon supported by AWS EKS. The 'addon_version' must be compatible with your cluster's Kubernetes version.

resource "aws_eks_addon" "efs_csi" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-efs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  resolve_conflicts_on_create  = "OVERWRITE"
  service_account_role_arn = aws_iam_role.eks_efs_csi_role.arn
}


# Data source: aws_iam_policy_document
# Generates an IAM policy document in JSON format that outlines the trust relationship for an IAM role.
# This template creates a trust policy for the Amazon EBS CSI driver, allowing it to assume an IAM role.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

data "aws_iam_policy_document" "ebs_csi_trust_policy" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_ip.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.eks_oidc_ip.arn), 3)}:aud"
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
      variable = "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.eks_oidc_ip.arn), 3)}:sub"
    }
  }
}


# Resource: aws_iam_role
# Creates an IAM role for the Amazon EBS CSI driver in an Amazon EKS cluster.
# The role grants permissions necessary for the driver to interact with AWS resources, specifically for managing EBS volumes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

# https://docs.aws.amazon.com/eks/latest/userguide/csi-iam-role.html
resource "aws_iam_role" "eks_ebs_csi_role" {
  description        = "This IAM Role is used for the AWS EBS CSI Driver"
  name               = join("-",[local.prefix,local.project,"eks-role",var.appname,"ebs-csi-driver"])
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]
}

# Resource: aws_eks_addon
# Manages an EKS cluster addon like "vpc-cni", "kube-proxy", or "coredns".
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
# Note: Ensure the 'cluster_name' matches the name of your EKS cluster and 'addon_name' is replaced
# with a valid addon supported by AWS EKS. The 'addon_version' must be compatible with your cluster's Kubernetes version.

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "PRESERVE"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.eks_ebs_csi_role.arn
}

# Data source: aws_iam_policy_document
# Generates an IAM policy document in JSON format that outlines the trust relationship for an IAM role.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

data "aws_iam_policy_document" "s3_csi_trust_policy" {
  statement {
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_ip.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.eks_oidc_ip.arn), 3)}:aud"
    }
    condition {
      test     = "StringEquals"
      values   = ["system:serviceaccount:kube-system:s3-csi-*"]
      variable = "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.eks_oidc_ip.arn), 3)}:sub"
    }
  }
}

# Resource: aws_iam_role
# Creates an IAM role for use with the AWS S3 CSI driver in an EKS cluster.
# This role includes a trust policy that allows entities (like Kubernetes service accounts) to assume this role
# More Info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

# https://docs.aws.amazon.com/eks/latest/userguide/s3-csi.html
resource "aws_iam_role" "eks_s3_csi_role" {
  description        = "This IAM Role is used for the AWS S3 CSI Driver"
  name               = join("-",[local.prefix,"eks-role",var.environment,var.appname,"ebs-csi-driver-role"])
  assume_role_policy = data.aws_iam_policy_document.s3_csi_trust_policy.json
  managed_policy_arns = [
    aws_iam_policy.eks_s3_csi_driver.arn
  ]
}

# Resource: aws_iam_policy
# Creates an IAM policy for the Amazon S3 CSI driver used within an EKS cluster. This policy specifies permissions required
# More Info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy

resource "aws_iam_policy" "eks_s3_csi_driver" {
  name        = join("-",[local.prefix,"policy",var.environment,var.appname,"eks-s3"])
  policy      = data.aws_iam_policy_document.s3_csi.json
  description = "Amazon S3 CSI Driver for EKS"
}


# Data source: aws_iam_policy_document
# Generates an IAM policy document in JSON format that outlines the trust relationship for an IAM role.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

data "aws_iam_policy_document" "s3_csi" {
  statement {
    sid       = "MountpointFullBucketAccess"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.s3_eks_bucket.arn]
  }
  statement {
    sid = "MountpointFullObjectAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.s3_eks_bucket.arn}/*"]
  }
}

# Resource: aws_eks_addon
# Manages an EKS cluster addon like "vpc-cni", "kube-proxy", or "coredns".
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon
# Note: Ensure the 'cluster_name' matches the name of your EKS cluster and 'addon_name' is replaced
# with a valid addon supported by AWS EKS. The 'addon_version' must be compatible with your cluster's Kubernetes version.

resource "aws_eks_addon" "s3_csi" {
  cluster_name                = aws_eks_cluster.eks_cluster.name
  addon_name                  = "aws-mountpoint-s3-csi-driver"
  resolve_conflicts_on_update = "PRESERVE"
  resolve_conflicts_on_create = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.eks_s3_csi_role.arn
}
