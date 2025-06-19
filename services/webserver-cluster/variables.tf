variable "cluster_name" {
  description = "The name to use for all the cluster resources"
  type = string
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket for the database remote state"
  type = string
}

variable "db_remote_state_key" {
  description = "The path to the key in the S3 bucket for the database remote state"
  type = string
}

variable "instance_type" {
  description = "The type of the EC2 instance to launch"
  type = string
}

variable "min_size" {
  description = "The minimum number of EC2 instances in the ASG"
  type = number
}

variable "max_size" {
  description = "The maximum number of EC2 instances in the ASG"
  type = number
}

variable "custom_tags" {
  description = "Custom tags to set on the resources"
  type = map(string)
  default = {}
}

variable "enable_autoscaling" {
  description = "If set to true, enable autoscaling"
  type = bool
}

variable "ami" {
  description = "The AMI to use for the instances"
  type = string
  default = "ami-0fb653ca2d3203ac1"
}

variable "server_text" {
  description = "The text the server will output"
  type = string
  default = "Hello, World"
}
