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
