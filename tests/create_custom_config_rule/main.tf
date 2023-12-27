module "create_config_rules" {
  source = "../../"

  config_recorder_id = module.config.config_recorder_id

  config_rule = {
    description                 = "Checks that IAM User Access Keys have been rotated within the specified number of days"
    maximum_execution_frequency = null
    name                        = "iam-access-key-rotation-check"
    owner                       = "CUSTOM_LAMBDA"
    source_identifier           = null
    tags                        = {}

    input_parameters = jsonencode({
      MaximumAccessKeyAge = "90"
    })

    source_details = [
      {
        message_type = "ConfigurationItemChangeNotification"
      },
      {
        message_type = "OversizedConfigurationItemChangeNotification"
      },
    ]

    scope = {
      compliance_resource_types = [
        "AWS::IAM::User",
      ]
      compliance_resource_id = null
      tag_key                = null
      tag_value              = null
    }
  }

  lambda = {
    description                    = "Checks that IAM User Access Keys have been rotated within the specified number of days"
    handler                        = "iam_access_key_rotation-triggered.handler"
    name                           = "config_rule_iam_access_key_rotation_check"
    policy                         = data.aws_iam_policy_document.lambda_iam_access_key_rotation_check.json
    runtime                        = "nodejs16.x"
    source_path                    = "${path.module}/.terraform/modules/vendor/node/iam_access_key_rotation-triggered.js"
    reserved_concurrent_executions = -1
    tags                           = {}
    timeout                        = 15
  }
}

module "vendor" {
  source = "git::https://github.com/plus3it/aws-config-rules.git?ref=e6fe305462333b26b55b30fc8586c4cf6f853907"
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=4.0.0"

  config_bucket = aws_s3_bucket.this.id
}

resource "aws_s3_bucket" "this" {
  bucket        = "tardigrade-config-rules-${random_string.this.result}"
  force_destroy = true
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

output "config_rule" {
  description = "AWS Config Rule object"
  value       = module.create_config_rules.config_rule
}
