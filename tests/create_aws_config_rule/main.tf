module "create_config_rules" {
  source = "../../"

  config_rule = {
    description                 = "Checks that your Amazon S3 buckets do not allow public read access. The rule checks the Block Public Access settings, the bucket policy, and the bucket access control list (ACL)"
    input_parameters            = null
    maximum_execution_frequency = null
    name                        = "s3-bucket-public-read-prohibited"
    owner                       = "AWS"
    scope                       = null
    source_details              = null
    source_identifier           = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
    tags                        = {}
  }

  config_recorder_id = module.config.config_recorder_id
}

module "config" {
  source = "git::https://github.com/plus3it/terraform-aws-tardigrade-config.git?ref=3.0.2"

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

output "config_rule" {
  description = "AWS Config Rule object"
  value       = module.create_config_rules.config_rule
}
