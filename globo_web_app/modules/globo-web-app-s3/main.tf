# S3 Bucket config#

resource "aws_s3_bucket" "web_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = var.common_tags
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
      identifiers = ["${var.elb_service_account_arn}"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/alb-logs/*"]
  }
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${var.bucket_name}/alb-logs/*"]
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
    resources = ["arn:aws:s3:::${var.bucket_name}"]
  }
}

resource "aws_iam_role" "allow_nginx_s3" {
  name               = "${var.bucket_name}-allow_nginx_s3"
  assume_role_policy = data.aws_iam_policy_document.allow_nginx_s3.json

  tags = var.common_tags
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
  name   = "${var.bucket_name}-allow_s3_all"
  role   = aws_iam_role.allow_nginx_s3.name
  policy = data.aws_iam_policy_document.allow_s3_all.json
}

data "aws_iam_policy_document" "allow_s3_all" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["arn:aws:s3:::${var.bucket_name}", "arn:aws:s3:::${var.bucket_name}/*"]
  }
}

resource "aws_iam_instance_profile" "nginx_profile" {
  name = "${var.bucket_name}-nginx_profile"
  role = aws_iam_role.allow_nginx_s3.name

  tags = var.common_tags
}
