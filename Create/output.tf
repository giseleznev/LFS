# Output value definitions

output "lambda_bucket_name" {
  description = "Name of the S3 bucket used to store function code."

  value = aws_s3_bucket.lambda_bucket.id
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.lambda_code.function_name
}
output "api-invoke-url" {
  value = "${aws_api_gateway_deployment.main.invoke_url}"
}


output "cert" {
  description = "API Gateway domain name"
  value = aws_acm_certificate.aws_cert.id
 }
