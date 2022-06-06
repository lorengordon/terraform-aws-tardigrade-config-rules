module "create_config_rules" {
  source   = "../../"
  for_each = local.config_rules

  config_recorder_id = module.config.config_recorder_id
  config_rule        = each.value
  lambda             = try(local.lambdas[each.key], null)
}

module "vendor" {
  source = "git::https://github.com/plus3it/aws-config-rules.git?ref=e6fe305462333b26b55b30fc8586c4cf6f853907"
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=3.0.2"

  config_bucket = aws_s3_bucket.this.id
}

resource "aws_s3_bucket" "this" {
  bucket        = "tardigrade-config-rules-${random_string.this.result}"
  force_destroy = true
}

resource "aws_sns_topic" "this" {
  name = "tardigrade-config-rules-${random_string.this.result}"
}

resource "random_string" "this" {
  length  = 6
  number  = false
  special = false
  upper   = false
}

data "aws_iam_policy_document" "lambda_iam_access_key_rotation_check" {
  statement {
    actions   = ["iam:ListAccessKeys"]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "lambda_iam_mfa_for_console_access" {
  statement {
    actions = [
      "iam:ListMFADevices",
      "iam:GetLoginProfile",
    ]

    resources = ["*"]
  }
}

locals {
  config_rules = {
    cloudtrail-enabled = merge(local.defaults.config_rule, {
      description       = "Checks whether AWS CloudTrail is enabled in your AWS account. Optionally, you can specify which S3 bucket, SNS topic, and Amazon CloudWatch Logs ARN to use"
      name              = "cloudtrail-enabled"
      owner             = "AWS"
      source_identifier = "CLOUD_TRAIL_ENABLED"

      input_parameters = jsonencode({
        s3BucketName = aws_s3_bucket.this.id,
      })
    })

    iam-password-policy = merge(local.defaults.config_rule, {
      description       = "Checks whether the account password policy for IAM users meets the specified requirements"
      name              = "iam-password-policy"
      owner             = "AWS"
      source_identifier = "IAM_PASSWORD_POLICY"

      input_parameters = jsonencode({
        RequireUppercaseCharacters = "true",
        RequireLowercaseCharacters = "true",
        RequireSymbols             = "true",
        RequireNumbers             = "true",
        MinimumPasswordLength      = "14",
        PasswordReusePrevention    = "24",
        MaxPasswordAge             = "60"
      })
    })

    s3-bucket-public-read-prohibited = merge(local.defaults.config_rule, {
      description       = "Checks that your Amazon S3 buckets do not allow public read access. The rule checks the Block Public Access settings, the bucket policy, and the bucket access control list (ACL)"
      name              = "s3-bucket-public-read-prohibited"
      owner             = "AWS"
      source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    })

    s3-bucket-public-write-prohibited = merge(local.defaults.config_rule, {
      description       = "Checks that your Amazon S3 buckets do not allow public write access. The rule checks the Block Public Access settings, the bucket policy, and the bucket access control list (ACL)"
      name              = "s3-bucket-public-write-prohibited"
      owner             = "AWS"
      source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
    })

    s3-bucket-ssl-requests-only = merge(local.defaults.config_rule, {
      description       = "Checks whether S3 buckets have policies that require requests to use Secure Socket Layer (SSL)"
      name              = "s3-bucket-ssl-requests-only"
      owner             = "AWS"
      source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
    })

    codebuild-project-envvar-awscred-check = merge(local.defaults.config_rule, {
      description       = "Checks whether the project contains environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY. The rule is NON_COMPLIANT when the project environment variables contains plaintext credentials"
      name              = "codebuild-project-envvar-awscred-check"
      owner             = "AWS"
      source_identifier = "CODEBUILD_PROJECT_ENVVAR_AWSCRED_CHECK"
    })

    codebuild-project-source-repo-url-check = merge(local.defaults.config_rule, {
      description       = "Checks whether the GitHub or Bitbucket source repository URL contains either personal access tokens or user name and password. The rule is COMPLIANT with the usage of OAuth to grant authorization for accessing GitHub or Bitbucket repositories"
      name              = "codebuild-project-source-repo-url-check"
      owner             = "AWS"
      source_identifier = "CODEBUILD_PROJECT_SOURCE_REPO_URL_CHECK"
    })

    instances-in-vpc = merge(local.defaults.config_rule, {
      description       = "Checks whether the GitHub or Bitbucket source repository URL contains either personal access tokens or user name and password. The rule is COMPLIANT with the usage of OAuth to grant authorization for accessing GitHub or Bitbucket repositories"
      name              = "instances-in-vpc"
      owner             = "AWS"
      source_identifier = "INSTANCES_IN_VPC"
    })

    ec2-volume-inuse-check = merge(local.defaults.config_rule, {
      description       = "Checks whether EBS volumes are attached to EC2 instances. Optionally checks if EBS volumes are marked for deletion when an instance is terminated"
      name              = "ec2-volume-inuse-check"
      owner             = "AWS"
      source_identifier = "EC2_VOLUME_INUSE_CHECK"
    })

    eip-attached = merge(local.defaults.config_rule, {
      description       = "Checks whether all Elastic IP addresses that are allocated to a VPC are attached to EC2 instances or in-use elastic network interfaces (ENIs)"
      name              = "eip-attached"
      owner             = "AWS"
      source_identifier = "EIP_ATTACHED"
    })

    lambda-function-public-access-prohibited = merge(local.defaults.config_rule, {
      description       = "Checks whether the AWS Lambda function policy attached to the Lambda resource prohibits public access. If the Lambda function policy allows public access it is NON_COMPLIANT"
      name              = "lambda-function-public-access-prohibited"
      owner             = "AWS"
      source_identifier = "LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED"
    })

    root-account-mfa-enabled = merge(local.defaults.config_rule, {
      description       = "Checks whether users of your AWS account require a multi-factor authentication (MFA) device to sign in with root credentials"
      name              = "root-account-mfa-enabled"
      owner             = "AWS"
      source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
    })

    restricted-common-ports-access = merge(local.defaults.config_rule, {
      description       = "Checks whether security groups that are in use disallow unrestricted incoming TCP traffic to the specified ports"
      name              = "restricted-common-ports-access"
      owner             = "AWS"
      source_identifier = "RESTRICTED_INCOMING_TRAFFIC"

      input_parameters = jsonencode({
        blockedPort1 = "22"
        blockedPort2 = "3389"
      })

      scope = merge(local.defaults.scope, {
        compliance_resource_types = [
          "AWS::IAM::SecurityGroup",
        ]
      })
    })

    restricted-common-ports-database = merge(local.defaults.config_rule, {
      description       = "Checks whether security groups that are in use disallow unrestricted incoming TCP traffic to the specified ports"
      name              = "restricted-common-ports-database"
      owner             = "AWS"
      source_identifier = "RESTRICTED_INCOMING_TRAFFIC"

      input_parameters = jsonencode({
        blockedPort1 = "1433"
        blockedPort2 = "1521"
        blockedPort3 = "3306"
        blockedPort4 = "4333"
        blockedPort5 = "5432"
      })

      scope = merge(local.defaults.scope, {
        compliance_resource_types = [
          "AWS::IAM::SecurityGroup",
        ]
      })
    })

    ebs-snapshot-public-restorable-check = merge(local.defaults.config_rule, {
      description                 = "Checks whether Amazon Elastic Block Store (Amazon EBS) snapshots are not publicly restorable. The rule is NON_COMPLIANT if one or more snapshots with RestorableByUserIds field are set to all, that is, Amazon EBS snapshots are public"
      maximum_execution_frequency = "TwentyFour_Hours"
      name                        = "ebs-snapshot-public-restorable-check"
      owner                       = "AWS"
      source_identifier           = "EBS_SNAPSHOT_PUBLIC_RESTORABLE_CHECK"
    })

    iam-user-active = merge(local.defaults.config_rule, {
      description       = "Checks whether your AWS Identity and Access Management (IAM) users have passwords or active access keys that have not been used within the specified number of days you provided"
      name              = "iam-user-active"
      owner             = "AWS"
      source_identifier = "IAM_USER_UNUSED_CREDENTIALS_CHECK"

      input_parameters = jsonencode({
        maxCredentialUsageAge = "90"
      })
    })


    iam-access-key-rotation-check = merge(local.defaults.config_rule, {
      description    = "Checks that IAM User Access Keys have been rotated within the specified number of days"
      name           = "iam-access-key-rotation-check"
      owner          = "CUSTOM_LAMBDA"
      source_details = local.source_details.configuration_change

      input_parameters = jsonencode({
        MaximumAccessKeyAge = "90"
      })

      scope = merge(local.defaults.scope, {
        compliance_resource_types = [
          "AWS::IAM::User",
        ]
      })
    })

    rds-vpc-public-subnet = merge(local.defaults.config_rule, {
      description    = "Checks that no RDS Instances are in a Public Subnet"
      name           = "rds-vpc-public-subnet"
      owner          = "CUSTOM_LAMBDA"
      source_details = local.source_details.configuration_change

      scope = merge(local.defaults.scope, {
        compliance_resource_types = [
          "AWS::RDS::DBInstance",
        ]
      })
    })

    config-enabled = merge(local.defaults.config_rule, {
      description    = "Checks that Config has been activated and is logging to a specific bucket and sending to a specifc SNS topic"
      name           = "config-enabled"
      owner          = "CUSTOM_LAMBDA"
      source_details = local.source_details.scheduled_notification

      input_parameters = jsonencode({
        s3BucketName = aws_s3_bucket.this.id
        snsTopicARN  = aws_sns_topic.this.arn
      })
    })

    iam-mfa-for-console-access = merge(local.defaults.config_rule, {
      description    = "Checks that all IAM users with console access have at least one MFA device"
      name           = "iam-mfa-for-console-access"
      owner          = "CUSTOM_LAMBDA"
      source_details = local.source_details.configuration_change

      scope = merge(local.defaults.scope, {
        compliance_resource_types = [
          "AWS::IAM::User",
        ]
      })
    })
  }

  lambdas = {
    iam-access-key-rotation-check = merge(local.defaults.lambda, {
      description = "Checks that IAM User Access Keys have been rotated within the specified number of days"
      handler     = "iam_access_key_rotation-triggered.handler"
      name        = "config_rule_iam_access_key_rotation_check"
      policy      = data.aws_iam_policy_document.lambda_iam_access_key_rotation_check.json
      runtime     = "nodejs10.x"
      source_path = "${local.source_path}/node/iam_access_key_rotation-triggered.js"
    })

    rds-vpc-public-subnet = merge(local.defaults.lambda, {
      description = "Checks that no RDS Instances are in a Public Subnet"
      handler     = "rds_vpc_public_subnet.lambda_handler"
      name        = "config_rule_rds_vpc_public_subnet"
      runtime     = "python3.6"
      source_path = "${local.source_path}/python/rds_vpc_public_subnet.py"
    })

    config-enabled = merge(local.defaults.lambda, {
      description = "Checks that Config has been activated and is logging to a specific bucket and sending to a specifc SNS topic"
      handler     = "config_enabled.lambda_handler"
      name        = "config_rule_config_enabled"
      runtime     = "python3.6"
      source_path = "${local.source_path}/python/config_enabled.py"
    })

    iam-mfa-for-console-access = merge(local.defaults.lambda, {
      description = "Checks that all IAM users with console access have at least one MFA device"
      handler     = "iam_mfa_for_console_access.lambda_handler"
      name        = "config_rule_iam_mfa_for_console_access"
      policy      = data.aws_iam_policy_document.lambda_iam_mfa_for_console_access.json
      runtime     = "python3.6"
      source_path = "${local.source_path}/python/iam_mfa_for_console_access.py"
    })
  }

  source_path = "${path.module}/.terraform/modules/vendor"

  defaults = {
    config_rule = {
      input_parameters            = null
      maximum_execution_frequency = null
      scope                       = null
      source_details              = null
      source_identifier           = null
      tags                        = null
    }

    scope = {
      compliance_resource_types = null
      compliance_resource_id    = null
      tag_key                   = null
      tag_value                 = null
    }

    lambda = {
      policy                         = null
      reserved_concurrent_executions = -1
      tags                           = null
      timeout                        = 15
    }
  }

  source_details = {
    configuration_change = [
      {
        message_type = "ConfigurationItemChangeNotification"
      },
      {
        message_type = "OversizedConfigurationItemChangeNotification"
      },
    ]

    scheduled_notification = [
      {
        message_type = "ScheduledNotification"
      },
    ]
  }
}

output "create_config_rules" {
  description = "Module object from create_config_rules"
  value       = module.create_config_rules
}
