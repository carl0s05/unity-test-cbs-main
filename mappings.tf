# Engineering Parameters
# Locals used in naming convention

locals {
    prefix = "bcpl"
    project = "cbs"
}

# Base Scalable Parameters
# Locals used to provide specifications of scale: CIDR, and sizes

locals {
    network_base = {
        dev = {
            vpc = "10.209.16.0/23"
            iso = "100.64.0.0/16"
            tgw = "200705036511"
        }
        qa = {
            vpc = "10.210.26.0/23"
            iso = "100.64.0.0/16"
            tgw = "200705036511"
        }
/*
        prd = {
            vpc = "XX.XX.XX.XX/16"
            iso = "100.64.0.0/16"
            tgw = "065841568145"
        }
*/
    }
}

locals {
    sizing = {
        dev = {
            amq_broker_size = "mq.t2.micro"
            eks_node_size = "r7i.xlarge"
            eks_cluster_desired_size = 3
            eks_cluster_max_size = 3
            eks_cluster_min_size = 3
        }
        qa = {
            amq_broker_size = "mq.t2.micro"
            eks_node_size = "r7i.xlarge"
            eks_cluster_desired_size = 3
            eks_cluster_max_size = 3
            eks_cluster_min_size = 3
        }
        prd = {
            amq_broker_size = "mq.t2.micro"
            eks_node_size = "r7i.xlarge"
            eks_cluster_desired_size = 3
            eks_cluster_max_size = 6
            eks_cluster_min_size = 3
        }
    }
}

# Name Parameters
# Locals used to provide specifications for naming, used ideally for elements that should be replicated, but name is relevant.

locals {
    names = {
        repository = {
            ecr-1 = "transact-web",
            ecr-2 = "transact-app",
            ecr-3 = "transact-batch",
            ecr-4 = "transact-api"
    }
  }
}

# Network Scalable Parameters
# Locals used for network creation. This determines the number of IP addresses available in a subnet.
# https://developer.hashicorp.com/terraform/language/functions/cidrsubnet
# The multiple routes, and the main routes used.

locals {
    network = {
        iso_subnet = {
            nodes-a = cidrsubnet(local.network_base[var.environment]["iso"], 2, 0),
            nodes-b = cidrsubnet(local.network_base[var.environment]["iso"], 2, 1),
            nodes-c = cidrsubnet(local.network_base[var.environment]["iso"], 2, 2),
            #nodes-d = cidrsubnet(local.network_base[var.environment]["iso"], 2, 3)
        },
        subnet = {
            eks-a = cidrsubnet(local.network_base[var.environment]["vpc"], 4, 0),
            eks-b = cidrsubnet(local.network_base[var.environment]["vpc"], 4, 1),
            eks-c = cidrsubnet(local.network_base[var.environment]["vpc"], 4, 2),
            alb-a = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 6),
            alb-b = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 7),
            alb-c = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 8),
            db-a = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 9),
            db-b = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 10),
            db-c = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 11),
            efs-a = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 12),
            efs-b = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 13),
            efs-c = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 14),
            mq-a = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 15),
            mq-b = cidrsubnet(local.network_base[var.environment]["vpc"], 5, 16),
            },
        route_table = [
            "priv-eks",
            "priv-mq",
            "priv-db",
            "priv-alb"
        ],
        routes_tgw = {
            priv-eks = "0.0.0.0/0",
            priv-db = "0.0.0.0/0",
            priv-alb = "0.0.0.0/0"
        },
        associaton = {
            eks-a = "priv-eks",
            eks-b = "priv-eks",
            eks-c = "priv-eks",
            mq-a = "priv-mq",
            mq-b = "priv-mq",
            db-a = "priv-db",
            db-b = "priv-db",
            db-c = "priv-db",
            alb-a = "priv-alb",
            alb-b = "priv-alb",
            alb-c = "priv-alb",
        }
    }
}