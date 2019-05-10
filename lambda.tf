# CREATE LAMBDA
# aws lambda invoke --region=us-west-2 --function-name=box-registry-api-get-box output.txt
# aws lambda invoke --region=us-west-2 --function-name=clemence-box-registry-boxes-create --payload='{ "serial_number": "2323" }' --invocation-type=RequestResponse --log-type=Tail /dev/stdout
# aws lambda invoke --region=us-west-2 --function-name=clemence-box-registry-boxes-get --payload='{ "id": "4f84f35e-bd42-4982-b183-77a9e8f0f28f" }' --invocation-type=RequestResponse --log-type=Tail /dev/stdout
# aws lambda invoke --region=us-west-2 --function-name=clemence-box-registry-boxes-update --payload='{ "id": "4f84f35e-bd42-4982-b183-77a9e8f0f28f", "serial_number": "22222" }' --invocation-type=RequestResponse --log-type=Tail /dev/stdout
# aws lambda invoke --region=us-west-2 --function-name=clemence-box-registry-boxes --invocation-type=RequestResponse --log-type=Tail /dev/stdout
resource "aws_lambda_function" "boxRegistryBoxes" {
  function_name = "clemence-box-registry-boxes"
  filename = "lambda_function.zip"
  source_code_hash = "${base64sha256(file("lambda_function.zip"))}"

  handler = "boxes_controller.BoxesController.index"
  runtime = "ruby2.5"

  role = "${aws_iam_role.lambda_exec.arn}"
}

# OUTPUT ARN TO USE TO INVOKE LAMBDA
output "arn INDEX" {
  value = "${aws_lambda_function.boxRegistryBoxes.arn}"
}

resource "aws_iam_role" "lambda_exec" {
  name = "clemence-lambda-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# DYNAMO DB PERMISSION
resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name = "clemence-lambda-dynamodb-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Action": [
                "dynamodb:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dynamodbLambdaAttach" {
  role       = "${aws_iam_role.lambda_exec.id}"
  policy_arn = "${aws_iam_policy.lambda_dynamodb_policy.arn}"
}


# API GATEWAY PERMISSION
resource "aws_lambda_permission" "apigwIndex" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.boxRegistryBoxes.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.boxRegistryApiGateway.execution_arn}/*/*"
}
