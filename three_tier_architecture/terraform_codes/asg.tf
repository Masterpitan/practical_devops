resource "aws_autoscaling_group" "app_asg" {
  name                      = "${var.env}-asg"
  desired_capacity          = var.app_desired_capacity
  min_size                  = var.app_min_size
  max_size                  = var.app_max_size
  health_check_type         = "ELB"
  health_check_grace_period = 600
  vpc_zone_identifier       = [for s in aws_subnet.private : s.id]
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.env}-app-asg"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  # Attach to ALB target group
  target_group_arns = [aws_lb_target_group.app_tg.arn]
}

# Optional scale policy (simple CPU target)
resource "aws_autoscaling_policy" "cpu_scale_up" {
  name                   = "${var.env}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
