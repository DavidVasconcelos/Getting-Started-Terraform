# S3 Bucket config#

resource "aws_s3_bucket" "web_bucket" {
  bucket        = local.s3_bucket_name
  force_destroy = true

  tags = local.common_tags
}

resource "aws_s3_bucket_acl" "web_bucket_acl" {
  bucket = aws_s3_bucket.web_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_policy" "allow_access_to_logs" {
  bucket = aws_s3_bucket.web_bucket.id
  policy = data.aws_iam_policy_document.allow_access_to_logs.json
}

data "aws_iam_policy_document" "allow_access_to_logs" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["${data.aws_elb_service_account.root.arn}"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.s3_bucket_name}/alb-logs/*"]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.s3_bucket_name}/alb-logs/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${local.s3_bucket_name}"]
  }
}

resource "aws_s3_object" "website" {
  bucket = aws_s3_bucket.web_bucket.id
  key    = "/website/index.html"
  source = "./website/index.html"

  tags = local.common_tags
}

resource "aws_s3_object" "graphic" {
  bucket = aws_s3_bucket.web_bucket.id
  key    = "/website/Globo_logo_Vert.png"
  source = "./website/Globo_logo_Vert.png"

  tags = local.common_tags

}

resource "aws_iam_role" "allow_nginx_s3" {
  name               = "allow_nginx_s3"
  assume_role_policy = data.aws_iam_policy_document.allow_nginx_s3.json

  tags = local.common_tags
}

data "aws_iam_policy_document" "allow_nginx_s3" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "allow_s3_all" {
  name   = "allow_s3_all"
  role   = aws_iam_role.allow_nginx_s3.name
  policy = data.aws_iam_policy_document.allow_s3_all.json
}

data "aws_iam_policy_document" "allow_s3_all" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${local.s3_bucket_name}", "arn:aws:s3:::${local.s3_bucket_name}/*"]
  }
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "nginx_profile"
  role = aws_iam_role.allow_nginx_s3.name

  tags = local.common_tags
}