resource "aws_cloudwatch_log_group" "tfer--ecs-002F-frontend-ecs-fargate-task" {
  log_group_class   = "STANDARD"
  name              = "ecs/frontend-ecs-fargate-task"
  retention_in_days = "14"
  skip_destroy      = "false"
}
