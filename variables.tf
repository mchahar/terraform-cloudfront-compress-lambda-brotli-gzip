variable "aws_region" {
  default     = "us-east-1"
  description = "AWS Region to host S3 site"
  type        = string
}

variable "domain_name" {
  description = "FQDN of cloudfront alias for the website - blog.site.com"
  type        = string
  default     = "mahesh-mt"
}


variable "tags" {
  default     = {}
  description = "Map of the tags for all resources"
  type        = map
}
