resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 30
}

resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts"
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "${var.project_name}-cpu-utilization-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ECS"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "CPU utilization high"
  alarm_actions      = [aws_sns_topic.alerts.arn]
  
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
  }
}
