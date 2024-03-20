# Resource: aws_mq_broker
# Creates an Amazon MQ broker, which provides a managed platform for Apache ActiveMQ or RabbitMQ messaging.
# This broker serves as a central point for message communication between different parts of your application,
# supporting both standard messaging protocols and wire formats.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_broker

resource "aws_mq_broker" "amq_broker" {
  auto_minor_version_upgrade = true
  broker_name                = join("-",[local.prefix,"mq",var.environment,var.appname,"broker"])
  configuration {
    id       = aws_mq_configuration.amq_configuration.id
    revision = aws_mq_configuration.amq_configuration.latest_revision
  }
  deployment_mode = "ACTIVE_STANDBY_MULTI_AZ"
  engine_type     = "ActiveMQ"
  engine_version  = "5.17.6"

  encryption_options {
    kms_key_id = aws_kms_key.amq_cmk.arn
    use_aws_owned_key = false
  }
  

  host_instance_type = local.sizing[var.environment]["amq_broker_size"]
  logs {
    general = true
    audit   = true
  }
  maintenance_window_start_time {
    day_of_week = "SUNDAY"
    time_of_day = "01:45"
    time_zone   = "America/Mexico_City"
  }
  publicly_accessible = "false"
  security_groups = [
    aws_security_group.amazon_mq_security_group.id
  ]
  subnet_ids = [
    aws_subnet.priv_subnet["mq-a"].id,
    aws_subnet.priv_subnet["mq-b"].id
  ]
  user {
    console_access = "true"
    groups         = [var.amq_brokergroup]
    password       = random_password.mq_password.result
    username       = var.p_amazon_mq_username
  }
}

# Resource: random_password
# Generates a random, high-entropy password for secure authentication purposes.
# This example generates a password for an Amazon MQ broker, ensuring that the password meets complexity requirements and is unique.
# More info: https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password

resource "random_password" "mq_password" {
  length           = 20
  override_special = "!#?@"
}

# Resource: aws_secretsmanager_secret
# Creates a new secret in AWS Secrets Manager to securely store sensitive information, such as passwords or API keys.
# This example demonstrates storing a password for an Amazon MQ broker, but it can be adapted for any type of sensitive data.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret

resource "aws_secretsmanager_secret" "mq_password" {
  #checkov:skip=CKV2_AWS_57:No rotation has been defined for this password
  name = join("/", ["",var.environment,var.appname,"mq","broker-password"])
  kms_key_id = aws_kms_key.amq_cmk.arn
  recovery_window_in_days = 0
}

# Resource: aws_secretsmanager_secret_version
# Adds a new version to a specified secret within AWS Secrets Manager, enabling the secure storage of sensitive information, such as passwords or keys.
# This example demonstrates storing the first version of a password for an Amazon MQ broker.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version

resource "aws_secretsmanager_secret_version" "first_version_mq" {
  secret_id     = aws_secretsmanager_secret.mq_password.id
  secret_string = random_password.mq_password.result
}

# Resource: aws_mq_configuration
# Creates a configuration that can be applied to Amazon MQ brokers. Configurations allow you to define settings such as
# message retention policies, logging, security settings, and more, enabling you to customize the behavior of your broker.
# This example shows how to create a basic configuration for an Amazon MQ broker.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/mq_configuration

resource "aws_mq_configuration" "amq_configuration" {
  #checkov:skip=CKV_AWS_208:The checkov code is not updated to check 5.17 is the newest version
  engine_type    = "ActiveMQ"
  engine_version = "5.17.6"
  name           = join("-", [local.prefix,"mq",var.environment,var.appname,"configuration"])
  data           = <<DATA
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<broker xmlns="http://activemq.apache.org/schema/core">
      <destinationPolicy>
        <policyMap>
          <policyEntries>
            <policyEntry topic=">">
              <pendingMessageLimitStrategy>
                <constantPendingMessageLimitStrategy limit="3000"/>
              </pendingMessageLimitStrategy>
            </policyEntry>
          </policyEntries>
        </policyMap>
      </destinationPolicy>
      <plugins>
      </plugins>
</broker>
DATA
}

# Resource: aws_security_group
# Defines a security group for controlling access to resources within your VPC. It acts as a virtual firewall.
# Security groups are crucial for defining inbound and outbound traffic rules to secure your resources.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group

resource "aws_security_group" "amazon_mq_security_group" {
  name        = join("-",[local.prefix, "sg", var.environment, var.appname, "mq-broker"])
  description = "Amazon MQ Broker Security Group"
  vpc_id      = aws_vpc.vpc.id
}


# Resource: aws_security_group_rule
# Adds a specific ingress rule to an existing security group to control access to resources, such as an Amazon MQ broker.
# This rule can specify IP ranges, protocols, ports, and the source security group to allow traffic from.
# This example demonstrates allowing TCP traffic on a specific port (e.g., the default port for MQ) from a defined CIDR block.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule

resource "aws_security_group_rule" "mq_access1" {
  type                     = "ingress"
  description              = "Access from TCP/5671"
  from_port                = 5671
  to_port                  = 5671
  protocol                 = "tcp"
  source_security_group_id = tolist(data.aws_launch_template.eks_nodes_lt.network_interfaces.0.security_groups)[0]
  security_group_id        = aws_security_group.amazon_mq_security_group.id
}

# Resource: aws_security_group_rule
# Adds a specific ingress rule to an existing security group to control access to resources, such as an Amazon MQ broker.
# This rule can specify IP ranges, protocols, ports, and the source security group to allow traffic from.
# This example demonstrates allowing TCP traffic on a specific port (e.g., the default port for MQ) from a defined CIDR block.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule

resource "aws_security_group_rule" "mq_access2" {
  type                     = "ingress"
  description              = "Access from TCP/15671"
  from_port                = 15671
  to_port                  = 15671
  protocol                 = "tcp"
  source_security_group_id = tolist(data.aws_launch_template.eks_nodes_lt.network_interfaces.0.security_groups)[0]
  security_group_id        = aws_security_group.amazon_mq_security_group.id
}

# Resource: aws_security_group_rule
# Adds a specific ingress rule to an existing security group to control access to resources, such as an Amazon MQ broker.
# This rule can specify IP ranges, protocols, ports, and the source security group to allow traffic from.
# This example demonstrates allowing TCP traffic on a specific port (e.g., the default port for MQ) from a defined CIDR block.
# More info: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule

resource "aws_security_group_rule" "mq_access3" {
  type                     = "ingress"
  description              = "Access from HTTPS"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = tolist(data.aws_launch_template.eks_nodes_lt.network_interfaces.0.security_groups)[0]
  security_group_id        = aws_security_group.amazon_mq_security_group.id
}