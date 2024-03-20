variable "appname" {
  description = "Name of the application, used in labeling"
  type    = string
}

variable "environment" {
  description = "Deploymemnt environment, used in labeling, and account selection"
  type    = string
}

variable "profile" {
  description = "Deployment profile, used for multi-account deploying"
  type    = string
}

variable "k8s_version" {
  description = "Kubernetes Version, this is defined by Temenos Team"
  type        = string
  default     = 1.24
}

variable amq_brokergroup {
  description = "Amazon MQ Group Name"
  type        = string
}

variable "p_amazon_mq_username" {
  description = "Amazon MQ Username"
  type        = string
}


variable "mgmt_vpc_cidr_access" {
  description = "The CIDR VPC from the management account. This is used for management purposes"
  type        = string
}