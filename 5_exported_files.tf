# Resource: local_file
# This Terraform resource creates a local file that defines a Kubernetes Service Account configuration.
# The file is specifically for the AWS Load Balancer Controller in the 'kube-system' namespace.
# More info: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file

resource "local_file" "alb_ctrl_sa" {
  content  = <<-EOF
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        labels:
          app.kubernetes.io/component: controller
          app.kubernetes.io/name: aws-load-balancer-controller
        name: aws-load-balancer-controller
        namespace: kube-system
        annotations:
          eks.amazonaws.com/role-arn: ${aws_iam_role.eks_elb_controller_role.arn}
      EOF
  filename = "outputs/aws-load-balancer-controller-service-account.yaml"
}

# Resource: local_file
# This Terraform resource creates a local file, specifically a shell script, that automates the installation of the AWS Load Balancer Controller in the 'kube-system' namespace of a Kubernetes cluster.
# More Info: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file

resource "local_file" "alb_ctrl_installer" {
  content  = <<-EOF
      kubectl apply -f aws-load-balancer-controller-service-account.yaml

      helm repo add eks https://aws.github.io/eks-charts
      helm repo update eks
      helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=${aws_eks_cluster.eks_cluster.name} \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller
      
      kubectl get deployment -n kube-system aws-load-balancer-controller
      kubectl describe deployment -n kube-system aws-load-balancer-controller
      EOF
  filename = "outputs/aws-load-balancer-controller-installer.sh"
}

# Resource: local_file
# This Terraform resource creates a local file that defines a Kubernetes Service Account configuration.
# This setup is crucial for leveraging S3 as a persistent storage solution in Kubernetes pods.
# More Info: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file


resource "local_file" "s3_csi_sa" {
  content  = <<-EOF
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        labels:
          app.kubernetes.io/name: aws-mountpoint-s3-csi-driver
        name: mountpoint-s3-csi-controller-sa
        namespace: kube-system
        annotations:
          eks.amazonaws.com/role-arn: ${aws_iam_role.eks_s3_csi_role.arn}
      EOF
  filename = "outputs/mountpoint-s3-service-account.yaml"
}

# Resource: local_file
# This Terraform resource creates a local shell script that facilitates the installation process of a custom or third-party AWS S3 CSI Driver in an Amazon EKS cluster.
# This script is a key part of setting up the S3 CSI driver.
# More Info: https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file

resource "local_file" "s3_csi_installer" {
  content  = <<-EOF
      kubectl apply -f mountpoint-s3-service-account.yaml
      kubectl get sa -n kube-system mountpoint-s3-csi-controller-sa
      EOF
  filename = "outputs/aws-s3-csi-driver-installer.sh"
}

data "aws_caller_identity" "current" {}

locals {
    account_id = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "upload_bucket" {
  bucket = join("-", ["eks", "config",var.appname, var.environment, local.account_id])
}

resource "aws_s3_bucket_public_access_block" "bpa_upload_bucket_s3" {
  bucket                  = aws_s3_bucket.upload_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "provision_files" {
  for_each = fileset("outputs/","**/*.*")
  bucket = aws_s3_bucket.upload_bucket.id
  key = each.value
  source = "outputs/${each.value}"
}

output "message" {
  value = "Check folder outputs on bucket: ${aws_s3_bucket.upload_bucket.id}"
}