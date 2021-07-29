# Input variable definitions

variable "aws_region" {
  description = "AWS region for all resources."

  type    = string
  default = "eu-north-1"
}

variable "bucket_name" {
  description = "AWS region for all resources."
  type    = string
  default = "lfsserverbucketname"
}

variable "bucket_name_for_certificate" {
  description = "AWS region for all resources."
  type    = string
  default = "lfsserverbucketnameforcertificate"
}

variable "dns_name" {
  description = "DNS Name"
  type    = string
  default = "updater.frozy.io"
}

variable "path_to_certificate" {
  description = "s3 adress Certificate for mTLS"
  type    = string
  default = "truststore.pem"
}
