provider "aws" {

  
  region     = "us-east-1"
  
}


resource "aws_iam_role" "lambda_role" {
 name   = "Email_lambdaRole"
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

# IAM policy for logging from a lambda

resource "aws_iam_policy" "iam_policy_for_lambda" {

  name         = "Email_POLICY"
  path         = "/"
  description  = "AWS IAM Policy for managing aws lambda role"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*",
        "ses:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Policy Attachment on the role.

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role        = aws_iam_role.lambda_role.name
  policy_arn  = aws_iam_policy.iam_policy_for_lambda.arn
}

# Generates an archive from content, a file, or a directory of files.

data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/Lambdacode.zip"
}

# Create a lambda function
# In terraform ${path.module} is the current directory.
resource "aws_lambda_function" "lambda_func" {
 filename                       = "${path.module}/python/Lambdacode.zip"
 function_name                  = "MassEmail_lambda_function1"
 role                           = aws_iam_role.lambda_role.arn
 handler                        = "Lambdacode.lambda_handler"
 runtime                        = "python3.7"
 depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}


resource "aws_s3_bucket" "listbucket" {
    
bucket = "emailscsv1"
acl = "private"

versioning {

    enabled = true
}
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = "${aws_s3_bucket.listbucket.id}"

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_func.arn
    events              = ["s3:ObjectCreated:*","s3:GetObject:*"]
    }

     depends_on = [
      aws_lambda_permission.test
    ]
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.listbucket.id}"
}
