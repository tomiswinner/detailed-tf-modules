provider "aws" {
  region = "us-east-2"
}

# Variables
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

# loccals は、tf ファイル内でのみ参照される変数、いわゆるマジックナンバー的なものはこれを使う
locals {
  http_port = 80
  any_port = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

# 他のリソースの tfstate の outputs 変数を参照するには、`terraform_remote_state` データソースを使用する
data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = "terraform-up-nad-running-state-test20250607"
    key = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

# VPC & Subnet
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# Security Group
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
}

## sg rule inbound
resource "aws_security_group_rule" "instance_allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.instance.id
  from_port = var.server_port
  to_port = var.server_port
  protocol = "tcp"
  cidr_blocks = local.all_ips
}


# Launch Template
# templatefile() はデフォルトでは、terraform apply 実行時のディレクトリを起点にファイルを探す
## path.module : 現在処理中のモジュールファイルが存在するパス
## path.root : terraform apply 実行時の起点となるファイルが存在するパス
## path.cwd : 現在のディレクトリ
resource "aws_launch_template" "example" {
  image_id = "ami-0fb653ca2d3203ac1"
  # https://stackoverflow.com/questions/31569910/terraform-throws-groupname-cannot-be-used-with-the-parameter-subnet-or-vpc-se
  vpc_security_group_ids = [aws_security_group.instance.id]
  instance_type = var.instance_type
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {  # テンプレートファイル = 文字列展開ができる, テンプレートとしてレンダリングできる、とかいうらしい
    server_port = var.server_port
    db_address = data.terraform_remote_state.db.outputs.address
    db_port = data.terraform_remote_state.db.outputs.port
  }))

  # なぜか asg + launch template の場合、create_before_destroy を設定しないと、更新時にエラーが出るらしい、、？
  # そもそも、asg の場合、古い launch conf への参照を持つので、その削除ができないからか
  lifecycle {
    create_before_destroy = true
  }
}


# ASG
resource "aws_autoscaling_group" "example" {
  launch_template {
    id = aws_launch_template.example.id
    version = "$Latest"
  }
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size = var.min_size
  max_size = var.max_size

  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-exapmle"
    propagate_at_launch = true
  }
  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
  # tf は先にリソースを削除して、その後リソースを作成する
  # asg の場合、古い launch conf への参照を持つので、その削除ができない
  # create_before_destroy を設定することで、古いリソースを先に削除して(古いリソースを更新 = asg が参照する launch conf が更新)から新しいリソースを作成する
  lifecycle {
    create_before_destroy = true   
  }
}



# ALB Security Group
resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

## sg rule inbound
resource "aws_security_group_rule" "alb_allow_http_inbound" {
  type = "ingress"
  security_group_id = aws_security_group.alb.id
  from_port = local.http_port
  to_port = local.http_port
  protocol = local.tcp_protocol
  cidr_blocks = local.all_ips
}

## sg rule outbound
resource "aws_security_group_rule" "alb_allow_all_outbound" {
  type = "egress"
  security_group_id = aws_security_group.alb.id
  from_port = local.any_port
  to_port = local.any_port
  protocol = local.any_protocol
  cidr_blocks = local.all_ips
}

# ALB
resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

# listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = local.http_port
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code = "404"
    }
  }
}

# target group
resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  target_type = "instance"
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


# listener rule
resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 10
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

