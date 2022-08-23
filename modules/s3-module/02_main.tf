resource "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
  tags   = var.tags_s3
}

resource "aws_s3_bucket_acl" "this" {
  bucket = var.s3_bucket_name
  acl    = var.s3_bucket_acl
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = var.s3_bucket_name
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = var.s3_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "this" {
  depends_on = [aws_s3_bucket_public_access_block.this]
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Deny"
    actions = [
      "s3:*",
    ]

    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}