data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_launch_template" "lt" {
  name_prefix   = "${var.asg_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.nginx_sg.id]
  }

  user_data = base64encode(templatefile("./userdata.sh.tpl", {
    cw_agent_config = base64encode(file("./cloudwatch-config.json"))
  }))
}

resource "aws_security_group" "nginx_sg" {
  name_prefix = "${var.asg_name}-sg-"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = var.asg_name
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  vpc_zone_identifier       = var.private_subnet_ids
  health_check_type         = "EC2"
  force_delete              = true
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  target_group_arns = [var.load_balancer_target_group_arn]

  tag {
    key                 = "Name"
    value               = var.asg_name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  scheduled_action {
    name                    = "${var.asg_name}-recycle"
    recurrence              = "0 0 */30 * *"
    min_size                = 1
    max_size                = 1
    desired_capacity        = 0
    time_zone               = "UTC"
  }

  scheduled_action {
    name                    = "${var.asg_name}-recycle-restart"
    recurrence              = "10 0 */30 * *"
    min_size                = 1
    max_size                = 1
    desired_capacity        = 1
    time_zone               = "UTC"
  }
}
