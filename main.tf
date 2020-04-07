provider "aws" {
  region = "us-east-1"
  alias  = "aws_cloudfront"
}
provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.domain_name}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}",
      ]
    }
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.domain_name
  acl    = "private"
  region = var.aws_region

  versioning {
    enabled = true
  }

  policy = data.aws_iam_policy_document.s3_bucket_policy.json

  tags = var.tags
}


// Cloudfront Distro with lambda@Edge integration
resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [aws_s3_bucket.s3_bucket]

  origin {
    domain_name = "${var.domain_name}.s3.amazonaws.com"
    origin_id   = "s3-cloudfront"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]

    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.folder_index_redirect.qualified_arn
      include_body = false
    }


    target_origin_id = "s3-cloudfront"

    forwarded_values {
      query_string = false
      headers      = [ "Accept-Encoding"]
      cookies {
        forward = "none"
      }
    }
      viewer_protocol_policy = "redirect-to-https"
      min_ttl = 0
      default_ttl = 0
      max_ttl = 0
  }
#ordered_cache_behavior {
#    path_pattern     = "/mtt/*"
#    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
#    cached_methods   = ["GET", "HEAD", "OPTIONS"]
#    target_origin_id = "s3-cloudfront"
#
#    forwarded_values {
#      query_string = false
#      headers      = ["Accept-Encoding"]
#      cookies {
#        forward = "none"
#      }
#    }
#
#    min_ttl                = 0
#    default_ttl            = 0
#    max_ttl                = 0
#    compress               = true
#    viewer_protocol_policy = "redirect-to-https"
#    lambda_function_association {
#      event_type = "origin-request"
#      lambda_arn = aws_lambda_function.folder_index_redirect.qualified_arn
#      include_body = false
#    }
#}

   restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  price_class = "PriceClass_100"
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "access-identity-${var.domain_name}.s3.amazonaws.com"
}
