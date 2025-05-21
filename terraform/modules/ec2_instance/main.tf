  data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners      = ["amazon"]
    filter {
      name   = "name"
      values = ["al2023-ami-*-x86_64"]
    }
  }
  data "aws_vpc" "default" {
    default = true
  }
  data "aws_subnets" "private" {
    filter {
      name   = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
  }
  resource "aws_iam_role" "ec2_role" {
    name = "${var.asg_name}-ec2-role"

    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        }
      ]
    })
  }
  resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  resource "aws_iam_instance_profile" "ec2_profile" {
    name = "${var.asg_name}-ec2-profile"
    role = aws_iam_role.ec2_role.name
  }

  resource "aws_launch_template" "lt" {
    name_prefix   = "${var.asg_name}-lt-"
    image_id      = data.aws_ami.amazon_linux_2023.id
    instance_type = "t3.micro"

    iam_instance_profile {
      name = aws_iam_instance_profile.ec2_profile.name
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
    vpc_zone_identifier = data.aws_subnets.private.ids
    vpc_security_group_ids = [aws_security_group.nginx_sg.id]
    max_instance_lifetime = 2592000
    health_check_type         = "EC2"
    force_delete              = true
    launch_template {
      id      = aws_launch_template.lt.id
      version = "$Latest"
    }
    target_group_arns = [var.load_balancer_target_group_arn]


  }

