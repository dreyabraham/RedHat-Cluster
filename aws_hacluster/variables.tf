variable "instances_per_subnet" {
  description = "Number of instance launched in public subnet"
  type        = number
  default     = 1
}
variable "ebs_size" {
  description = "Number of instance launched in public subnet"
  type        = number
  default     = 10
}

variable "ebs_device_name" {
  description = "EBS device name"
  type        = string
  default     = "/dev/sdh"
}

variable "instance_type" {
  description = "Node instance type"
  type        = string
  default     = "t2.micro"
}

variable "aws_ami_id" {
  description = "Node ami id"
  type        = string
  default     = "ami-002070d43b0a4f171"
}

variable "ansible_user" {
  description = "User with which ansible configure"
  type        = string
  default     = "centos"
}

variable "private_key" {
  description = "User required to login to ec2-instance by ansible"
  type        = string
  default     = "/home/ubuntu/redhat-cluster/aws_hacluster/ha-cluster.pem" #"/path/to/Your key"
}

variable "private_key_name" {
  description = "The name of the private key to be created"
  type        = string
  default     = "ha-cluster"
}
