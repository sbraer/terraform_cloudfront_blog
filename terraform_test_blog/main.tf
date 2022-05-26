terraform {
  required_version = "~> 1.00"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-south-1"
}

variable "s3bucketname" {
    description = "Bucket name"
    type = string
    default = "az-site2"  
}

resource "aws_s3_bucket" "site" {
  bucket = var.s3bucketname
  force_destroy = true
}

################################################################################################
resource "aws_s3_bucket_object" "html" {
  for_each = fileset("../output/dist/", "**/*.html")
  bucket = aws_s3_bucket.site.id
  key = each.value
  source = "../output/dist/${each.value}"
  etag = filemd5("../output/dist/${each.value}")
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "svg" {
  for_each = fileset("../output/dist/", "**/*.svg")
  bucket = aws_s3_bucket.site.id
  key = each.value
  source = "../output/dist/${each.value}"
  etag = filemd5("../output/dist/${each.value}")
  content_type = "image/svg+xml"
}

resource "aws_s3_bucket_object" "css" {
  for_each = fileset("../output/dist/", "**/*.css")
  bucket = aws_s3_bucket.site.id
  key = each.value
  source = "../output/dist/${each.value}"
  etag = filemd5("../output/dist/${each.value}")
  content_type = "text/css"
}

resource "aws_s3_bucket_object" "js" {
  for_each = fileset("../output/dist/", "**/*.js")
  bucket = aws_s3_bucket.site.id
  key = each.value
  source = "../output/dist/${each.value}"
  etag = filemd5("../output/dist/${each.value}")
  content_type = "application/javascript"
}

resource "aws_s3_bucket_object" "png" {
  for_each = fileset("../output/dist/", "**/*.png")
  bucket = aws_s3_bucket.site.id
  key = each.value
  source = "../output/dist/${each.value}"
  etag = filemd5("../output/dist/${each.value}")
  content_type = "image/png"
}

resource "aws_s3_bucket_object" "json" {
  for_each = fileset("../output/dist/", "**/*.json")
  bucket = aws_s3_bucket.site.id
  key = each.value
  source = "../output/dist/${each.value}"
  etag = filemd5("../output/dist/${each.value}")
  content_type = "application/json"
}

################################################################################################

resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_acl" "site" {
  bucket = aws_s3_bucket.site.id
  acl = "public-read"
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource = [
          aws_s3_bucket.site.arn,
          "${aws_s3_bucket.site.arn}/*",
        ]
      },
    ]
  })
}

################################################################################################

data "archive_file" "website" {
  output_path = "../output/zip/website.zip"
  source_dir  = "../output/dist"
  type        = "zip"
}

resource "null_resource" "website" {
  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --paths /*"
  }

  triggers = {
    index = filebase64sha256(data.archive_file.website.output_path)
  }
}

################################################################################################
locals {
  s3_origin_id = "mysite"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "mysite"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.site.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "my-cloudfront"
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https" #"allow-all"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE", "IN", "IR", "IT"]
    }
  }

  tags = {
    Environment = "development"
    Name        = "my-tag"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

################################################################################################

output "cloudfront" {
  description = "DNS output from cloudfront"
  value = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}"
}