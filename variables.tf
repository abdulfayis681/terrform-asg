variable "region" {
  type = string
  default = "us-east-1"
}

variable "image_id" {
  type = string
  default = "ami-03ededff12e34e59e"
}

variable "flavor" {
  type = string
  default = "t2.micro"
}

variable "ec2_instance_port" {
  type = number
  default = 80
}
