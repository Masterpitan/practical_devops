# AMI lookup (Amazon Linux 2)
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
/*
# IAM Role for SSM (optional, useful for management)
resource "aws_iam_role" "ec2_role" {
  name = "${var.env}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.env}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
*/
# User data for app instances (simple nginx)
data "template_file" "userdata" {
  template = <<-EOF
            #!/bin/bash
            yum update -y
            amazon-linux-extras install -y nginx1
            systemctl enable nginx
            systemctl start nginx
            echo "<h1>Hello from ${var.env} app instance $(hostname)</h1>" > /usr/share/nginx/html/index.html
            EOF
}

resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.env}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
#  iam_instance_profile {
 #   name = aws_iam_instance_profile.ec2_profile.name
  #}

  key_name = var.key_pair_name != "" ? var.key_pair_name : null

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(data.template_file.userdata.rendered)

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.env}-app-instance"
    }
  }
}
