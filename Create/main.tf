terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.bucket_name
  acl           = "aws-exec-read"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.lambda_bucket.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${var.bucket_name}/*"
        }
    ]
})
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.lambda_bucket.id
	block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "certificate_bucket" {
  bucket = var.bucket_name_for_certificate
  acl           = "private"
  force_destroy = true
}

data "archive_file" "lambda_code" {
  type = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_s3_bucket_object" "cert" {
  bucket = aws_s3_bucket.certificate_bucket.id
  key    = "truststore.pem"
  source = var.path_to_certificate

  etag = filemd5(var.path_to_certificate)
}

resource "aws_s3_bucket_object" "lambda_code" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key    = "lambda.zip"
  source = data.archive_file.lambda_code.output_path

  etag = filemd5(data.archive_file.lambda_code.output_path)
}

resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda_code" {
  function_name = "PostResponse"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda_code.key

  runtime = "python3.7"
  handler = "lambda_function.lambda_handler"

  source_code_hash = data.archive_file.lambda_code.output_base64sha256

  role = aws_iam_role.iam_for_lambda.arn
	environment {
		variables = {
			bucket_name = aws_s3_bucket.lambda_bucket.id
    }
  }
}

resource "aws_api_gateway_rest_api" "lfs" {
  #disable_execute_api_endpoint = true
  name = "LFS"
  description = "LFS API GW"
}

resource "aws_api_gateway_resource" "lfs" {
  rest_api_id = aws_api_gateway_rest_api.lfs.id
  parent_id   = aws_api_gateway_rest_api.lfs.root_resource_id
  path_part   = "objects"
}

resource "aws_api_gateway_resource" "lfs2" {
  rest_api_id = aws_api_gateway_rest_api.lfs.id
  parent_id   = aws_api_gateway_resource.lfs.id
  path_part   = "batch"
}

resource "aws_api_gateway_method" "lfs_post_method" {
  rest_api_id = "${aws_api_gateway_rest_api.lfs.id}"
  resource_id = "${aws_api_gateway_resource.lfs2.id}"
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_iam_role" "api-gateway" {
  name = "myroleforlfs"
  description = "Managed by Terraform"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "api-gateway" {
  name = "LambdaPolicy"
  role = "${aws_iam_role.api-gateway.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": [
        "*"
      ]
    }
  ]
}
EOF
}

resource "aws_api_gateway_integration" "lfs_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.lfs.id}"
  resource_id = "${aws_api_gateway_resource.lfs2.id}"
  http_method = "${aws_api_gateway_method.lfs_post_method.http_method}"
  integration_http_method = "${aws_api_gateway_method.lfs_post_method.http_method}"
  type = "AWS"
  uri = "arn:aws:apigateway:eu-north-1:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda_code.arn}/invocations"
  credentials = "${aws_iam_role.api-gateway.arn}"
}

resource "aws_api_gateway_method_response" "OK" {
  rest_api_id = "${aws_api_gateway_rest_api.lfs.id}"
  resource_id = "${aws_api_gateway_resource.lfs2.id}"
  http_method = "${aws_api_gateway_method.lfs_post_method.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "lfs_integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.lfs.id}"
  resource_id = "${aws_api_gateway_resource.lfs2.id}"
  http_method = "${aws_api_gateway_method.lfs_post_method.http_method}"
  status_code = "${aws_api_gateway_method_response.OK.status_code}"
  depends_on = [aws_api_gateway_integration.lfs_integration]
}

resource "aws_api_gateway_rest_api_policy" "test" {
  rest_api_id = aws_api_gateway_rest_api.lfs.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "execute-api:Invoke",
      "Resource": "arn:aws:execute-api:eu-north-1:*:${aws_api_gateway_rest_api.lfs.id}/*/POST/objects/batch"
    }
  ]
}
EOF
}

resource "aws_acm_certificate" "aws_cert" {
  domain_name       = var.dns_name
  validation_method = "DNS"
}


resource "aws_acm_certificate_validation" "aws_cert" {
	certificate_arn         = aws_acm_certificate.aws_cert.arn
}


resource "aws_api_gateway_domain_name" "domain" {
   depends_on = [
    aws_acm_certificate_validation.aws_cert
  ]
  domain_name = var.dns_name
  regional_certificate_arn = aws_acm_certificate.aws_cert.arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
  security_policy = "TLS_1_2"
  
  mutual_tls_authentication {
    truststore_uri = "s3://${var.bucket_name_for_certificate}/${aws_s3_bucket_object.cert.key}"
  } 
}

resource "aws_api_gateway_base_path_mapping" "example" {
  api_id      = aws_api_gateway_rest_api.lfs.id
  stage_name  = aws_api_gateway_deployment.main.stage_name
  domain_name = aws_api_gateway_domain_name.domain.domain_name
}

resource "aws_api_gateway_deployment" "main" {
  depends_on = [aws_api_gateway_integration.lfs_integration]
  rest_api_id = aws_api_gateway_rest_api.lfs.id
  stage_name  = "test"
  variables = {
    "answer" = "answer"
  }
}
