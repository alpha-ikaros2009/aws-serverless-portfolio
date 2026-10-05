# CloudFront: HTTPS termination + CDN in front of the private S3 origin (OAC),
# with an /api/* behavior forwarding to the API Gateway HTTP API so frontend
# and API share one origin (no extra CORS surface in production).

resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.name_prefix}-site-oac"
  description                       = "OAC for the static site S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  http_version        = "http2and3"
  default_root_object = "index.html"
  price_class         = "PriceClass_100"
  comment             = "${local.name_prefix} portfolio site"

  origin {
    origin_id                = "s3-site"
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  origin {
    origin_id   = "api-gateway"
    domain_name = trimprefix(aws_apigatewayv2_api.api.api_endpoint, "https://")

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id = local.cloudfront_caching_optimized_policy_id
  }

  # API traffic is never cached; all viewer headers except Host are forwarded
  # (Host must stay the CloudFront host for TLS to the API origin).
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "api-gateway"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id          = local.cloudfront_caching_disabled_policy_id
    origin_request_policy_id = local.cloudfront_all_viewer_except_host_header_policy
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Phase 1: default *.cloudfront.net certificate (free, zero setup).
  # Phase 2: switch to an ACM certificate + aliases for a custom domain.
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
