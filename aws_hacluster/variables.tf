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
  default     = "ami-05548f9cecf47b442"
}

variable "ansible_user" {
  description = "User with which ansible configure"
  type        = string
  default     = "ec2-user"
}

variable "private_key" {
  description = "User required to login to ec2-instance by ansible"
  type        = string
  default     = "/home/ubuntu/redhat-cluster/aws_hacluster/ha-cluster.pem" #"/home/ec2-user/aws_hacluster_terraform/aws_hacluster/Your key"
}

variable "private_key_name" {
  description = "The name of the private key to be created"
  type        = string
  default     = "ha-cluster"
}
