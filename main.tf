
provider "aws" {
  region = var.region
  access_key = "AKIAYDEO3BRTRJVL7ONH"
  secret_key = "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"
}
resource "aws_security_group" "alb-sec-group" {
  name = "alb-sec-group_fxyiee"
  description = "Security Group for the ELB (ALB)"
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "asg_sec_group" {
  name = "asg_sec_group"
  description = "Security Group for the ASG"
  tags = {
    name = "name"
  }
  // outbound 
  egress {
    from_port = 0
    protocol = "-1" // ALL Protocols
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  // inbound
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    security_groups = [aws_security_group.alb-sec-group.id]
  }
}
resource "aws_launch_configuration" "ec2_template" {
  image_id = var.image_id
  instance_type = var.flavor
  user_data = <<-EOF
            #!/bin/bash
            yum -y update
            yum -y install httpd
            echo "hey fayis  !" > /var/www/html/index.html
            systemctl start httpd
            systemctl enable httpd
            EOF
  security_groups = [aws_security_group.asg_sec_group.id]
lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

#creating asg

resource "aws_autoscaling_group" "asg_tutorial_day1" {
  max_size = 1
  min_size = 1
  launch_configuration = aws_launch_configuration.ec2_template.name
  health_check_grace_period = 300
  
  
  health_check_type = "ELB"
  
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  
  target_group_arns = [aws_lb_target_group.asg.arn]
  
  tag {
    key = "day1_asg"
    propagate_at_launch = false
    value = "day1_asg"
  }
  lifecycle {
  create_before_destroy = true
  }
}
resource "aws_lb" "ELB" {
  name               = "terraform-asg-example"
  load_balancer_type = "application"

subnets  = data.aws_subnet_ids.default.ids
  security_groups = [aws_security_group.alb-sec-group.id]
}
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ELB.arn
  port = 80
  protocol = "HTTP"
  
  
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}
resource "aws_lb_target_group" "asg" {
  name = "asg-example"
  port = var.ec2_instance_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}


resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  condition {
    path_pattern {
      values = ["*"]
    }
  }
}


  

