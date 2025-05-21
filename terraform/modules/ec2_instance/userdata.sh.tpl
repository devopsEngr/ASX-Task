#!/bin/bash
yum update -y
yum install -y nginx amazon-cloudwatch-agent

systemctl enable nginx
systemctl start nginx
systemctl status nginx


echo "${cw_agent_config}" | base64 -d > /opt/aws/amazon-cloudwatch-agent/bin/config.json
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json \
    -s
