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

            # Install Node.js 18 and nginx
            curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
            yum install -y nodejs git nginx

            # Clone your app
            cd /home/ec2-user
            git clone https://github.com/yourusername/your-repo.git reader-app
            chown -R ec2-user:ec2-user reader-app

            # Setup server
            cd reader-app/server
            sudo -u ec2-user npm install

            # Create environment file
            cat > .env << EOL
DATABASE_URL="postgresql://postgres:m5mxhWbB*vJd6_Q@db.jmuoffnxerwetfglxono.supabase.co:5432/postgres"
EOL

            # Setup client
            cd ../client
            sudo -u ec2-user npm install

            # Create client environment
            cat > .env.local << EOL
NEXT_PUBLIC_API_URL=http://localhost:3001/
EOL

            # Build client
            sudo -u ec2-user npm run build

            # Install PM2 for process management
            npm install -g pm2

            # Start server
            cd ../server
            sudo -u ec2-user pm2 start npm --name "reader-server" -- run start:prod

            # Start client
            cd ../client
            sudo -u ec2-user pm2 start npm --name "reader-client" -- start

            # Configure nginx as reverse proxy
            cat > /etc/nginx/conf.d/reader.conf << EOL
server {
    listen 80;
    server_name _;
    
    # API routes
    location /api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Client routes (default)
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL
            
            # Remove default nginx config
            rm -f /etc/nginx/conf.d/default.conf
            
            # Start nginx
            systemctl enable nginx
            systemctl start nginx
            
            # Save PM2 processes
            sudo -u ec2-user pm2 save
            sudo -u ec2-user pm2 startup
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
