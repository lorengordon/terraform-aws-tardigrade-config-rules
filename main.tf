provider "aws" {
}

locals {
  exclude_cloudtrail_enabled                       = "${contains(var.exclude_rules, "cloudtrail_enabled")}"
  exclude_iam_password_policy                      = "${contains(var.exclude_rules, "iam_password_policy")}"
  exclude_s3_bucket_public_read_prohibited         = "${contains(var.exclude_rules, "s3_bucket_public_read_prohibited")}"
  exclude_s3_bucket_public_write_prohibited        = "${contains(var.exclude_rules, "s3_bucket_public_write_prohibited")}"
  exclude_s3_bucket_ssl_requests_only              = "${contains(var.exclude_rules, "s3_bucket_ssl_requests_only")}"
  exclude_codebuild_project_envvar_awscred_check   = "${contains(var.exclude_rules, "codebuild_project_envvar_awscred_check")}"
  exclude_codebuild_project_source_repo_url_check  = "${contains(var.exclude_rules, "codebuild_project_source_repo_url_check")}"
  exclude_instances_in_vpc                         = "${contains(var.exclude_rules, "instances_in_vpc")}"
  exclude_ec2_volume_inuse_check                   = "${contains(var.exclude_rules, "ec2_volume_inuse_check")}"
  exclude_eip_attached                             = "${contains(var.exclude_rules, "eip_attached")}"
  exclude_lambda_function_public_access_prohibited = "${contains(var.exclude_rules, "lambda_function_public_access_prohibited")}"
  exclude_root_account_mfa_enabled                 = "${contains(var.exclude_rules, "root_account_mfa_enabled")}"
  exclude_iam_access_key_rotation_check            = "${contains(var.exclude_rules, "iam_access_key_rotation_check")}"
  exclude_rds_vpc_public_subnet                    = "${contains(var.exclude_rules, "rds_vpc_public_subnet")}"
  exclude_iam_user_active                          = "${contains(var.exclude_rules, "iam_user_active")}"
  exclude_config_enabled                           = "${contains(var.exclude_rules, "config_enabled")}"
  exclude_iam_mfa_for_console_access               = "${contains(var.exclude_rules, "iam_mfa_for_console_access")}"
  exclude_restricted_common_ports_access           = "${contains(var.exclude_rules, "restricted_common_ports_access")}"
  exclude_restricted_common_ports_database         = "${contains(var.exclude_rules, "restricted_common_ports_database")}"
  exclude_ebs_snapshot_public_restorable_check     = "${contains(var.exclude_rules, "ebs_snapshot_public_restorable_check")}"
}

locals {
  aws_config_rules = "${path.module}/vendor/github.com/awslabs/aws-config-rules"
}

data "aws_partition" "current" {
  count = var.create_config_rules ? 1 : 0
}

data "aws_caller_identity" "this" {
  count = var.create_config_rules ? 1 : 0
}

data "template_file" "cloudtrail_enabled" {
  count = var.create_config_rules ? 1 : 0

  template = <<-EOF
    {"s3BucketName":"$${cloudtrail_bucket}"}
  EOF


  vars = {
    cloudtrail_bucket = var.cloudtrail_bucket
  }
}

data "template_file" "iam_password_policy" {
  count = var.create_config_rules ? 1 : 0

  template = <<-EOF
    {
      "RequireUppercaseCharacters":"true",
      "RequireLowercaseCharacters":"true",
      "RequireSymbols":"true",
      "RequireNumbers":"true",
      "MinimumPasswordLength":"14",
      "PasswordReusePrevention":"24",
      "MaxPasswordAge":"60"
    }
  EOF

}

resource "null_resource" "dependencies" {
  count = var.create_config_rules ? 1 : 0

  triggers = {
    config_recorder = var.config_recorder
  }
}

resource "aws_config_config_rule" "cloudtrail_enabled" {
  count = var.create_config_rules && ! local.exclude_cloudtrail_enabled ? 1 : 0

  name             = "cloudtrail-enabled"
  description      = "Checks whether AWS CloudTrail is enabled in your AWS account. Optionally, you can specify which S3 bucket, SNS topic, and Amazon CloudWatch Logs ARN to use"
  input_parameters = data.template_file.cloudtrail_enabled[0].rendered

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "iam_password_policy" {
  count = var.create_config_rules && ! local.exclude_iam_password_policy ? 1 : 0

  name             = "iam-password-policy"
  description      = "Checks whether the account password policy for IAM users meets the specified requirements"
  input_parameters = data.template_file.iam_password_policy[0].rendered

  source {
    owner             = "AWS"
    source_identifier = "IAM_PASSWORD_POLICY"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  count = var.create_config_rules && ! local.exclude_s3_bucket_public_read_prohibited ? 1 : 0

  name        = "s3-bucket-public-read-prohibited"
  description = "Checks that your Amazon S3 buckets do not allow public read access. The rule checks the Block Public Access settings, the bucket policy, and the bucket access control list (ACL)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  count = var.create_config_rules && ! local.exclude_s3_bucket_public_write_prohibited ? 1 : 0

  name        = "s3-bucket-public-write-prohibited"
  description = "Checks that your Amazon S3 buckets do not allow public write access. The rule checks the Block Public Access settings, the bucket policy, and the bucket access control list (ACL)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  count = var.create_config_rules && ! local.exclude_s3_bucket_ssl_requests_only ? 1 : 0

  name        = "s3-bucket-ssl-requests-only"
  description = "Checks whether S3 buckets have policies that require requests to use Secure Socket Layer (SSL)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "codebuild_project_envvar_awscred_check" {
  count = var.create_config_rules && ! local.exclude_codebuild_project_envvar_awscred_check ? 1 : 0

  name        = "codebuild-project-envvar-awscred-check"
  description = "Checks whether the project contains environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY. The rule is NON_COMPLIANT when the project environment variables contains plaintext credentials"

  source {
    owner             = "AWS"
    source_identifier = "CODEBUILD_PROJECT_ENVVAR_AWSCRED_CHECK"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "codebuild_project_source_repo_url_check" {
  count = var.create_config_rules && ! local.exclude_codebuild_project_source_repo_url_check ? 1 : 0

  name        = "codebuild-project-source-repo-url-check"
  description = "Checks whether the GitHub or Bitbucket source repository URL contains either personal access tokens or user name and password. The rule is COMPLIANT with the usage of OAuth to grant authorization for accessing GitHub or Bitbucket repositories"

  source {
    owner             = "AWS"
    source_identifier = "CODEBUILD_PROJECT_SOURCE_REPO_URL_CHECK"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "instances_in_vpc" {
  count = var.create_config_rules && ! local.exclude_instances_in_vpc ? 1 : 0

  name        = "instances-in-vpc"
  description = "Checks whether your EC2 instances belong to a virtual private cloud (VPC). Optionally, you can specify the VPC ID to associate with your instances"

  source {
    owner             = "AWS"
    source_identifier = "INSTANCES_IN_VPC"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "ec2_volume_inuse_check" {
  count = var.create_config_rules && ! local.exclude_ec2_volume_inuse_check ? 1 : 0

  name        = "ec2-volume-inuse-check"
  description = "Checks whether EBS volumes are attached to EC2 instances. Optionally checks if EBS volumes are marked for deletion when an instance is terminated"

  source {
    owner             = "AWS"
    source_identifier = "EC2_VOLUME_INUSE_CHECK"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "eip_attached" {
  count = var.create_config_rules && ! local.exclude_eip_attached ? 1 : 0

  name        = "eip-attached"
  description = "Checks whether all Elastic IP addresses that are allocated to a VPC are attached to EC2 instances or in-use elastic network interfaces (ENIs)"

  source {
    owner             = "AWS"
    source_identifier = "EIP_ATTACHED"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "lambda_function_public_access_prohibited" {
  count = var.create_config_rules && ! local.exclude_lambda_function_public_access_prohibited ? 1 : 0

  name        = "lambda-function-public-access-prohibited"
  description = "Checks whether the AWS Lambda function policy attached to the Lambda resource prohibits public access. If the Lambda function policy allows public access it is NON_COMPLIANT"

  source {
    owner             = "AWS"
    source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "root_account_mfa_enabled" {
  count = var.create_config_rules && ! local.exclude_root_account_mfa_enabled ? 1 : 0

  name        = "root-account-mfa-enabled"
  description = "Checks whether users of your AWS account require a multi-factor authentication (MFA) device to sign in with root credentials"

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [null_resource.dependencies]
}

resource "aws_config_config_rule" "iam_user_active" {
  count = var.create_config_rules && ! local.exclude_iam_user_active ? 1 : 0

  name        = "iam-user-active"
  description = "Checks whether your AWS Identity and Access Management (IAM) users have passwords or active access keys that have not been used within the specified number of days you provided"

  input_parameters = <<-EOF
    {
      "maxCredentialUsageAge":"90"
    }
  EOF

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"
  }

  depends_on = [null_resource.dependencies]
}

###########################
### CUSTOM CONFIG RULES ###
###########################
data "aws_iam_policy" "config_rules" {
  count = var.create_config_rules ? 1 : 0

  arn = "arn:${data.aws_partition.current[0].partition}:iam::aws:policy/service-role/AWSConfigRulesExecutionRole"
}

### iam_access_key_rotation_check
data "aws_iam_policy_document" "lambda_iam_access_key_rotation_check" {
  count = var.create_config_rules && ! local.exclude_iam_access_key_rotation_check ? 1 : 0

  source_json = data.aws_iam_policy.config_rules[0].policy

  statement {
    actions   = ["iam:ListAccessKeys"]
    resources = ["*"]
  }
}

module "lambda_iam_access_key_rotation_check" {
  source = "git::https://github.com/plus3it/terraform-aws-lambda.git?ref=v1.1.0"

  function_name = "config_rule_iam_access_key_rotation_check"
  description   = "Checks that IAM User Access Keys have been rotated within the specified number of days"
  handler       = "iam_access_key_rotation-triggered.handler"
  runtime       = "nodejs10.x"
  timeout       = 15
  tags          = var.tags

  reserved_concurrent_executions = "-1"

  source_path = "${local.aws_config_rules}/node/iam_access_key_rotation-triggered.js"

  policy = var.create_config_rules ? data.aws_iam_policy_document.lambda_iam_access_key_rotation_check[0] : null
}

resource "aws_lambda_permission" "iam_access_key_rotation_check" {
  count = var.create_config_rules && ! local.exclude_iam_access_key_rotation_check ? 1 : 0

  action         = "lambda:InvokeFunction"
  function_name  = module.lambda_iam_access_key_rotation_check.function_name
  principal      = "config.amazonaws.com"
  source_account = data.aws_caller_identity.this[0].account_id
}

resource "aws_config_config_rule" "iam_access_key_rotation_check" {
  count = var.create_config_rules && ! local.exclude_iam_access_key_rotation_check ? 1 : 0

  name        = "iam-access-key-rotation-check"
  description = "Checks that IAM User Access Keys have been rotated within the specified number of days"

  input_parameters = <<-EOF
    {
      "MaximumAccessKeyAge": "90"
    }
  EOF


  scope {
    compliance_resource_types = ["AWS::IAM::User"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = module.lambda_iam_access_key_rotation_check.function_arn

    source_detail {
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      message_type = "OversizedConfigurationItemChangeNotification"
    }
  }

  depends_on = [
    aws_lambda_permission.iam_access_key_rotation_check,
    null_resource.dependencies,
  ]
}

### rds_vpc_public_subnet
data "aws_iam_policy_document" "lambda_rds_vpc_public_subnet" {
  count = var.create_config_rules && ! local.exclude_rds_vpc_public_subnet ? 1 : 0

  source_json = data.aws_iam_policy.config_rules[0].policy

  statement {
    actions   = ["ec2:DescribeRouteTables"]
    resources = ["*"]
  }
}

module "lambda_rds_vpc_public_subnet" {
  source = "git::https://github.com/plus3it/terraform-aws-lambda.git?ref=v1.1.0"

  function_name = "config_rule_rds_vpc_public_subnet"
  description   = "Checks that no RDS Instances are in a Public Subnet"
  handler       = "rds_vpc_public_subnet.lambda_handler"
  runtime       = "python3.6"
  timeout       = 15
  tags          = var.tags

  reserved_concurrent_executions = "-1"

  source_path = "${local.aws_config_rules}/python/rds_vpc_public_subnet.py"

  policy = var.create_config_rules ? data.aws_iam_policy_document.lambda_iam_access_key_rotation_check[0] : null
}

resource "aws_lambda_permission" "rds_vpc_public_subnet" {
  count = var.create_config_rules && ! local.exclude_rds_vpc_public_subnet ? 1 : 0

  action         = "lambda:InvokeFunction"
  function_name  = module.lambda_rds_vpc_public_subnet.function_name
  principal      = "config.amazonaws.com"
  source_account = data.aws_caller_identity.this[0].account_id
}

resource "aws_config_config_rule" "rds_vpc_public_subnet" {
  count = var.create_config_rules && ! local.exclude_rds_vpc_public_subnet ? 1 : 0

  name        = "rds-vpc-public-subnet"
  description = "Checks that no RDS Instances are in a Public Subnet"

  scope {
    compliance_resource_types = ["AWS::RDS::DBInstance"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = module.lambda_rds_vpc_public_subnet.function_arn

    source_detail {
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      message_type = "OversizedConfigurationItemChangeNotification"
    }
  }

  depends_on = [
    aws_lambda_permission.rds_vpc_public_subnet,
    null_resource.dependencies,
  ]
}

### config_enabled
data "aws_iam_policy_document" "lambda_config_enabled" {
  count = "${var.create_config_rules && ! local.exclude_config_enabled ? 1 : 0}"

  source_json = "${data.aws_iam_policy.config_rules[0].policy}"
}

module "lambda_config_enabled" {
  source = "git::https://github.com/plus3it/terraform-aws-lambda.git?ref=v1.1.0"

  function_name = "config_rule_config_enabled"
  description   = "Checks that Config has been activated and is logging to a specific bucket and sending to a specifc SNS topic"
  handler       = "config_enabled.lambda_handler"
  runtime       = "python3.6"
  timeout       = 15
  tags          = var.tags

  reserved_concurrent_executions = "-1"

  source_path = "${local.aws_config_rules}/python/config_enabled.py"

  policy = var.create_config_rules ? data.aws_iam_policy_document.lambda_config_enabled[0] : null
}

resource "aws_lambda_permission" "config_enabled" {
  count = var.create_config_rules && ! local.exclude_config_enabled ? 1 : 0

  action         = "lambda:InvokeFunction"
  function_name  = module.lambda_config_enabled.function_name
  principal      = "config.amazonaws.com"
  source_account = data.aws_caller_identity.this[0].account_id
}

resource "aws_config_config_rule" "config_enabled" {
  count = var.create_config_rules && ! local.exclude_config_enabled ? 1 : 0

  name        = "config-enabled"
  description = "Checks that Config has been activated and is logging to a specific bucket and sending to a specifc SNS topic"

  input_parameters = <<-EOF
    {
      "s3BucketName": "${var.config_bucket}",
      "snsTopicARN": "${var.config_sns_topic_arn}"
    }
  EOF


  scope {
    compliance_resource_types = ["AWS::IAM::User"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = module.lambda_config_enabled.function_arn

    source_detail {
      message_type = "ScheduledNotification"
    }
  }

  depends_on = [
    aws_lambda_permission.config_enabled,
    null_resource.dependencies,
  ]
}

### iam_mfa_for_console_access
data "aws_iam_policy_document" "lambda_iam_mfa_for_console_access" {
  count = var.create_config_rules && ! local.exclude_iam_mfa_for_console_access ? 1 : 0

  source_json = data.aws_iam_policy.config_rules[0].policy

  statement {
    actions = [
      "iam:ListMFADevices",
      "iam:GetLoginProfile",
    ]

    resources = ["*"]
  }
}

module "lambda_iam_mfa_for_console_access" {
  source = "git::https://github.com/plus3it/terraform-aws-lambda.git?ref=v1.2.0"

  function_name = "config_rule_iam_mfa_for_console_access"
  description   = "Checks that all IAM users with console access have at least one MFA device"
  handler       = "iam_mfa_for_console_access.lambda_handler"
  runtime       = "python3.6"
  timeout       = 15
  tags          = var.tags

  reserved_concurrent_executions = "-1"

  source_path = "${local.aws_config_rules}/python/iam_mfa_for_console_access.py"

  policy = var.create_config_rules ? data.aws_iam_policy_document.lambda_iam_mfa_for_console_access[0] : null
}

resource "aws_lambda_permission" "iam_mfa_for_console_access" {
  count = var.create_config_rules && ! local.exclude_iam_mfa_for_console_access ? 1 : 0

  action         = "lambda:InvokeFunction"
  function_name  = module.lambda_iam_mfa_for_console_access.function_name
  principal      = "config.amazonaws.com"
  source_account = data.aws_caller_identity.this[0].account_id
}

resource "aws_config_config_rule" "iam_mfa_for_console_access" {
  count = var.create_config_rules && ! local.exclude_iam_mfa_for_console_access ? 1 : 0

  name        = "iam-mfa-for-console-access"
  description = "Checks that all IAM users with console access have at least one MFA device"

  scope {
    compliance_resource_types = ["AWS::IAM::User"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = module.lambda_iam_mfa_for_console_access.function_arn

    source_detail {
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      message_type = "OversizedConfigurationItemChangeNotification"
    }
  }

  depends_on = [
    aws_lambda_permission.iam_mfa_for_console_access,
    null_resource.dependencies,
  ]
}

### RESTRICTED COMMON PORTS: ACCESS
resource "aws_config_config_rule" "restricted_common_ports_access" {
  count = var.create_config_rules && ! local.exclude_restricted_common_ports_access ? 1 : 0

  name        = "restricted-common-ports-access"
  description = "Checks whether security groups that are in use disallow unrestricted incoming TCP traffic to the specified ports."

  input_parameters = <<-EOF
    {
      "blockedPort1": "22",
      "blockedPort2": "3389"
    }
  EOF

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  depends_on = [null_resource.dependencies]
}

### RESTRICTED COMMON PORTS: DATABASE
resource "aws_config_config_rule" "restricted_common_ports_database" {
  count = var.create_config_rules && ! local.exclude_restricted_common_ports_database ? 1 : 0

  name        = "restricted-common-ports-database"
  description = "Checks whether security groups that are in use disallow unrestricted incoming TCP traffic to the specified ports."

  input_parameters = <<-EOF
    {
      "blockedPort1": "1433",
      "blockedPort2": "1521",
      "blockedPort3": "3306",
      "blockedPort4": "4333",
      "blockedPort5": "5432"
    }
  EOF

  scope {
    compliance_resource_types = ["AWS::EC2::SecurityGroup"]
  }

  source {
    owner             = "AWS"
    source_identifier = "RESTRICTED_INCOMING_TRAFFIC"
  }

  depends_on = [null_resource.dependencies]
}

### EBS SNAPSHOT PUBLIC RESTORABLE
resource "aws_config_config_rule" "ebs_snapshot_public_restorable_check" {
  count = var.create_config_rules && ! local.exclude_ebs_snapshot_public_restorable_check ? 1 : 0

  name                        = "ebs-snapshot-public-restorable-check"
  description                 = "Checks whether Amazon Elastic Block Store (Amazon EBS) snapshots are not publicly restorable. The rule is NON_COMPLIANT if one or more snapshots with RestorableByUserIds field are set to all, that is, Amazon EBS snapshots are public."
  input_parameters            = "{}"
  maximum_execution_frequency = "TwentyFour_Hours"

  source {
    owner             = "AWS"
    source_identifier = "EBS_SNAPSHOT_PUBLIC_RESTORABLE_CHECK"
  }

  depends_on = [null_resource.dependencies]
}
