# Data source: tls_certificate
# Retrieves information about a TLS certificate from a given domain. This can be useful for verifying
# the details of a certificate, such as its issuer, validity period, and subject details, before configuring
# certificate issuers or other TLS/SSL-related configurations in your infrastructure.
# Note: This data source does not create a certificate; it simply retrieves information about an existing certificate.
# More info: https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate

data "tls_certificate" "cluster_issuer" {
  url = "https://oidc.eks.${data.aws_region.current.name}.amazonaws.com"
}

# Resource: aws_iam_openid_connect_provider
# Creates an IAM OpenID Connect (OIDC) provider. This is often used with Amazon EKS to allow Kubernetes service accounts to assume IAM roles.
# By setting up an OIDC provider, you can establish trust between your EKS cluster and AWS IAM, enabling fine-grained access control to AWS resources from within Kubernetes pods.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider

resource "aws_iam_openid_connect_provider" "eks_oidc_ip" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_issuer.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

# Data source: aws_iam_policy_document
# Generates an IAM policy document in JSON format that defines a trust relationship for the Elastic Load Balancer (ELB) controller in an Amazon EKS cluster.
# This trust policy allows the ELB controller to assume an IAM role, providing it with the necessary permissions to manage ELB resources on behalf of the user.
# Trust policies are a crucial component of IAM roles, specifying which principals (entities) are allowed to assume the role.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document

data "aws_iam_policy_document" "elb_controller_trust_policy" {
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
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
      variable = "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${element(split("/", aws_iam_openid_connect_provider.eks_oidc_ip.arn), 3)}:sub"
    }
  }
}


# Resource: aws_iam_role
# This resource creates an IAM role that entities can assume under certain conditions.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role

# https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.6/
resource "aws_iam_role" "eks_elb_controller_role" {
  description        = "This IAM Role is used for the AWS LB Controller"
  name               = join("-",[local.prefix,local.project,"eks-role",var.appname,"elb-controller"])
  assume_role_policy = data.aws_iam_policy_document.elb_controller_trust_policy.json
  managed_policy_arns = [
    aws_iam_policy.eks_aws_lb_controller.arn
  ]
}

# Data source: http
# Retrieves data from a given HTTP URL. This example demonstrates fetching a JSON policy for the AWS Load Balancer Controller,
# which could be used within an Amazon EKS environment. It's useful for dynamically obtaining policies or other configurations
# that are hosted externally and need to be integrated into your Terraform setup.
# More info: https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http

data "http" "aws_lb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.2/docs/install/iam_policy.json"
  request_headers = {
    Accept = "application/json"
  }
}

# Resource: aws_iam_policy
# Creates an IAM policy for the AWS Load Balancer Controller in an Amazon EKS cluster.
# This policy grants the necessary permissions for the controller to manage AWS Load Balancers on behalf of your Kubernetes workloads.
# It's a critical component for enabling automatic Load Balancer provisioning in response to Kubernetes Ingress objects or Service annotations.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy

resource "aws_iam_policy" "eks_aws_lb_controller" {
  name        = join("-",[local.prefix,local.project,"policy",var.appname,"elb-controller"])
  policy      = tostring(data.http.aws_lb_controller_policy.response_body)
  description = "Load Balancer Controller add-on for EKS"
}
