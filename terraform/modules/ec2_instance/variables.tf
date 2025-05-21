variable "asg_name" {
  description = "Name of the Auto Scaling group"
  type        = string
}

variable "load_balancer_target_group_arn" {
  description = "ARN of the load balancer target group"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "instance_profile_name" {
  description = "Name of the instance profile with SSM and CloudWatch permissions"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ASG and EC2s are deployed"
  type        = string
}
