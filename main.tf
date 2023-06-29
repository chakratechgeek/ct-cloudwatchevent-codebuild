
resource "aws_codecommit_repository" "test" {
  repository_name = "BuildTestRepository"
}

resource "aws_codebuild_project" "build_test" {
  name = "BuildTest"
  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts = {
    type = "NO_ARTIFACTS"
  }

  environment = {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/python:3.5.2"
    type = "LINUX_CONTAINER"
  }

  source {
  type = "GITHUB"
  location = "https://github.com/chakratechgeek/ct-cloudwatchevent-codebuild"
}

}

resource "aws_cloudwatch_event_rule" "schedule_rule" {
  name = "scheduled_build"
  schedule_expression = "rate(2 minutes)"
}

resource "aws_iam_role" "codebuild_role" {
  name = "us_build_test_codebuild_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "events.amazonaws.com",
          "codebuild.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_policy" {
  name = "us_build_test_policy"
  path = "/service-role/"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:*:local.account_id:log-group:/aws/codebuild/BuildTest",
                "arn:aws:logs:*:local.account_id:log-group:/aws/codebuild/BuildTest:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
          {
            "Action": [
              "codebuild:StartBuild",
              "codebuild:StopBuild",
              "codebuild:BatchGet*",
              "codebuild:Get*",
              "codebuild:List*",
              "codecommit:GetBranch",
              "codecommit:GetCommit",
              "codecommit:GetRepository",
              "codecommit:ListBranches"
            ],
            "Effect": "Allow",
            "Resource": "*"
          }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "service_role_attachment" {
  name = "build_test_policy_attachment"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles = ["${aws_iam_role.codebuild_role.id}"]
}

resource "aws_cloudwatch_event_target" "trigger_build" {
  target_id = "trigger_build"
  rule = "${aws_cloudwatch_event_rule.schedule_rule.name}"
  arn = "${aws_codebuild_project.build_test.id}"

  role_arn = "${aws_iam_role.codebuild_role.arn}"
}