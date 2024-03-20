# Resource: aws_kms_key
# This resource creates an AWS KMS key used for encrypting your ECR repository images.
# KMS keys provide added security by using encryption to protect your images. It's highly recommended for sensitive or private images.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key

#   # It's recommended to enable 'enable_key_rotation' for regularly rotating the encryption key to reduce potential risks.
# Note: Remember to attach the KMS key to your ECR repository to ensure images are encrypted. This requires modifying the ECR repository resource to use the KMS key for encryption.


resource "aws_kms_key" "ecr_cmk" {
  #checkov:skip=CKV2_AWS_64:KMS Policy is not yet defined
  description             = "Elastic Container Registry Managed Key"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

# Resource: aws_kms_alias
# Creates an alias for an AWS KMS key, providing a simpler way to reference the key in AWS services and applications.
# KMS aliases are useful for managing and accessing KMS keys more easily, especially when integrating with other AWS services like EKS for encryption purposes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias

resource "aws_kms_alias" "ecr_cmk_alias" {
  name          = "alias/kms/eks"
  target_key_id = aws_kms_key.ecr_cmk.key_id
}



# Resource: aws_kms_key
# This resource creates an AWS KMS key used for encrypting your ECR repository images.
# KMS keys provide added security by using encryption to protect your images. It's highly recommended for sensitive or private images.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key

#   # It's recommended to enable 'enable_key_rotation' for regularly rotating the encryption key to reduce potential risks.

resource "aws_kms_key" "eks_cmk" {
  #checkov:skip=CKV2_AWS_64:KMS Policy is not yet defined
  description             = "KMS Secrets Customer Managed Key"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

# Resource: aws_kms_alias
# Creates an alias for an AWS KMS key, providing a simpler way to reference the key in AWS services and applications.
# KMS aliases are useful for managing and accessing KMS keys more easily, especially when integrating with other AWS services like EKS for encryption purposes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias

resource "aws_kms_alias" "eks_cmk_alias" {
  name          = "alias/kms/ecr"
  target_key_id = aws_kms_key.eks_cmk.key_id
}

# Resource: aws_kms_key
# Creates a customer master key (CMK) in AWS Key Management Service (KMS) for cryptographic operations, such as encrypting and decrypting data.
# This example demonstrates creating a CMK for encrypting data associated with an Amazon MQ broker.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key

resource "aws_kms_key" "amq_cmk" {
  #checkov:skip=CKV2_AWS_64:KMS Policy is not yet defined
  description             = "Amazon MQ Managed Key"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

# Resource: aws_kms_alias
# Creates an alias for an AWS KMS key, providing a simpler way to reference the key in AWS services and applications.
# KMS aliases are useful for managing and accessing KMS keys more easily, especially when integrating with other AWS services like EKS for encryption purposes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias

resource "aws_kms_alias" "amq_cmk_alias" {
  name          = "alias/kms/amq"
  target_key_id = aws_kms_key.amq_cmk.key_id
}

# Resource: aws_kms_key
# This resource creates an AWS KMS key used for encrypting your ECR repository images.
# KMS keys provide added security by using encryption to protect your images. It's highly recommended for sensitive or private images.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key

#   # It's recommended to enable 'enable_key_rotation' for regularly rotating the encryption key to reduce potential risks.

resource "aws_kms_key" "s3_cbs" {
  #checkov:skip=CKV2_AWS_64:KMS Policy is not yet defined
  description             = "Amazon S3 Managed Key"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

# Resource: aws_kms_alias
# Creates an alias for an AWS KMS key, providing a simpler way to reference the key in AWS services and applications.
# KMS aliases are useful for managing and accessing KMS keys more easily, especially when integrating with other AWS services like EKS for encryption purposes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias

resource "aws_kms_alias" "s3_cbs_alias" {
  name          = "alias/s3_cbs"
  target_key_id = aws_kms_key.s3_cbs.key_id
}

# Resource: aws_kms_key
# This resource creates an AWS KMS key used for encrypting your ECR repository images.
# KMS keys provide added security by using encryption to protect your images. It's highly recommended for sensitive or private images.
# For more info, visit: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key

#   # It's recommended to enable 'enable_key_rotation' for regularly rotating the encryption key to reduce potential risks.

resource "aws_kms_key" "efs_cbs" {
  #checkov:skip=CKV2_AWS_64:KMS Policy is not yet defined
  description             = "Amazon EFS Managed Key"
  deletion_window_in_days = 7
  enable_key_rotation = true
}

# Resource: aws_kms_alias
# Creates an alias for an AWS KMS key, providing a simpler way to reference the key in AWS services and applications.
# KMS aliases are useful for managing and accessing KMS keys more easily, especially when integrating with other AWS services like EKS for encryption purposes.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias

resource "aws_kms_alias" "efs_cbs_alias" {
  name          = "alias/efs_cbs"
  target_key_id = aws_kms_key.efs_cbs.key_id
}