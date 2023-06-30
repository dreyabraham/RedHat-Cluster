terraform {
  required_providers {
    aws = {
      version = "~> 4.0.0"
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  #access_key="YOUR ACCESS KEY"
  #secret_key="YOUR SECRET KEY"
}

resource "aws_vpc" "hacluster_vpc" {
  cidr_block = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    "Name" = "ha"
  }
}

resource "aws_subnet" "hapublic-1" {
  depends_on = [ aws_vpc.hacluster_vpc ]
  vpc_id = aws_vpc.hacluster_vpc.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "us-east-2a" 
  map_public_ip_on_launch = true
  tags = {
    "Name" = "public_Subnet-1"
  }
}

resource "aws_subnet" "hapublic-2" {
  depends_on = [ aws_vpc.hacluster_vpc ]
  vpc_id = aws_vpc.hacluster_vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    "Name" = "public_Subnet-2"
  }
}

resource "aws_internet_gateway" "gw" {
  depends_on = [aws_vpc.hacluster_vpc, aws_subnet.hapublic-1, aws_subnet.hapublic-2]
  vpc_id = aws_vpc.hacluster_vpc.id
  tags = {
    "Name" = "ha_gw"
  }
}

resource "aws_route_table" "haroute" {
  depends_on = [ aws_internet_gateway.gw ]
  vpc_id = aws_vpc.hacluster_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
   "Name" = "public-rule"
  }
}

resource "aws_route_table_association" "subnetAssociation1" {
  depends_on = [ aws_route_table.haroute ]
  subnet_id = aws_subnet.hapublic-1.id
  route_table_id = aws_route_table.haroute.id
}

resource "aws_route_table_association" "subnetAssociation2" {
  depends_on = [ aws_route_table.haroute ]
  subnet_id = aws_subnet.hapublic-2.id
  route_table_id = aws_route_table.haroute.id
}

resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.hacluster_vpc.id
  route_table_id = aws_route_table.haroute.id
}

resource "aws_security_group" "allowed_rules" {
  depends_on = [ aws_vpc.hacluster_vpc ]
  name = "hacluster"
  description = "Security Group rules for the HAcluster"
  vpc_id = aws_vpc.hacluster_vpc.id
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing ssh connectivity"
    from_port = 22
    protocol = "tcp"
    to_port = 22
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing pcsd connectivity"
    from_port = 2224
    protocol = "tcp"
    to_port = 2224
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing crmd connectivity"
    from_port = 3121
    protocol = "tcp"
    to_port = 3121
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing corosync-qnetd connectivity"
    from_port = 5403
    protocol = "tcp"
    to_port = 5403
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing corosync multicast-udp connectivity"
    from_port = 5404
    protocol = "udp"
    to_port = 5404
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing corosync connectivity"
    from_port = 5405
    protocol = "udp"
    to_port = 5405
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing CLVM connectivity"
    from_port = 21064
    protocol = "tcp"
    to_port = 21064
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing booth-ticket manager connectivity"
    from_port = 9929
    protocol = "tcp"
    to_port = 9929
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing booth-ticket manager connectivity"
    from_port = 9929
    protocol = "udp"
    to_port = 9929
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allowing booth-ticket manager connectivity"
    from_port = 9929
    protocol = "udp"
    to_port = 9929
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "Allow all"
    from_port = 0
    protocol = "-1"
    to_port = 0
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "NFS"
    from_port = 2049
    protocol = "tcp"
    to_port = 2049
  }
  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    protocol = -1
    to_port = 0
  }
  tags = {
    "Name" = "HA-firewall-rules"
  }
}


resource "aws_efs_file_system" "hacluster_efs" {
creation_token = "hacluster_efs"
tags = {
Name = "hacluster_efs"
}
}

resource "aws_efs_mount_target" "mount-1" {
depends_on = [ aws_vpc.hacluster_vpc ]
file_system_id = aws_efs_file_system.hacluster_efs.id
subnet_id =aws_subnet.hapublic-1.id
security_groups = [   aws_security_group.allowed_rules.id  ]
}

resource "aws_efs_mount_target" "mount-2" {
depends_on = [ aws_vpc.hacluster_vpc ]
file_system_id = aws_efs_file_system.hacluster_efs.id
subnet_id =aws_subnet.hapublic-2.id
security_groups = [   aws_security_group.allowed_rules.id  ]
}

resource "null_resource" "configure_nfs1" {
depends_on = [aws_efs_mount_target.mount-1, aws_efs_file_system.hacluster_efs]
connection {
type     = "ssh"
user     = "ec2-user"
private_key = tls_private_key.my_key.private_key_pem
host     = aws_eip.EIP1.public_ip
 }
provisioner "remote-exec" {
inline = [
"sudo yum install httpd php git -y -q ",
"sudo systemctl start httpd",
"sudo systemctl enable httpd",
"sudo yum install nfs-utils -y -q ",
# Mounting Efs 
"sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.hacluster_efs.dns_name}:/  /var/www/html",
# Making Mount Permanent
"sudo chmod 777 /etc/fstab",
"echo ${aws_efs_file_system.hacluster_efs.dns_name}:/ /var/www/html nfs4 defaults,_netdev 0 0  | sudo cat >> /etc/fstab " ,
"sudo chmod go+rw /var/www/html",
"touch /var/www/html/index.html",
  ]
 }
}

resource "null_resource" "configure_nfs2" {
depends_on = [aws_efs_mount_target.mount-2, aws_efs_file_system.hacluster_efs]
connection {
type     = "ssh"
user     = "ec2-user"
private_key = tls_private_key.my_key.private_key_pem
host     = aws_eip.EIP2.public_ip
provisioner "remote-exec" {
inline = [
"sudo yum install httpd php git -y -q ",
"sudo systemctl start httpd",
"sudo systemctl enable httpd",
"sudo yum install nfs-utils -y -q ",
# Mounting Efs 
"sudo mount -t nfs -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${aws_efs_file_system.hacluster_efs.dns_name}:/  /var/www/html",
# Making Mount Permanent
"sudo chmod 777 /etc/fstab",
"echo ${aws_efs_file_system.hacluster_efs.dns_name}:/ /var/www/html nfs4 defaults,_netdev 0 0  | sudo cat >> /etc/fstab " ,
"sudo chmod go+rw /var/www/html",
"touch /var/www/html/index.html",
  ]
 }
}
}

resource "tls_private_key" "my_key" {
algorithm = "RSA"
}

resource "aws_key_pair" "deployer" {
key_name   = "efs-key"
public_key = tls_private_key.my_key.public_key_openssh
}

resource "null_resource" "save_key_pair"  {
provisioner "local-exec" {
command = "echo  ${tls_private_key.my_key.private_key_pem} > mykey.pem"
}
}

resource "aws_instance" "ha-nodes-1" {
ami = "ami-02d1e544b84bf7502"
instance_type = "t2.micro"
key_name = aws_key_pair.deployer.key_name
subnet_id = aws_subnet.hapublic-1.id
vpc_security_group_ids = [ aws_security_group.allowed_rules.id ]
depends_on = [ aws_efs_mount_target.mount-1]
}

resource "aws_instance" "ha-nodes-2" {
ami = "ami-02d1e544b84bf7502"
instance_type = "t2.micro"
key_name = aws_key_pair.deployer.key_name
subnet_id = aws_subnet.hapublic-2.id
vpc_security_group_ids = [ aws_security_group.allowed_rules.id ]
depends_on = [ aws_efs_mount_target.mount-2]
}

resource "aws_eip" "EIP1" {
  instance = aws_instance.ha-nodes-1.id
  vpc      = true
  tags = {
    Name = "EC2-EIP"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_eip" "EIP2" {
  instance = aws_instance.ha-nodes-2.id
  vpc      = true
  tags = {
    Name = "EC2-EIP"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_storagegateway_gateway" "example" {
  gateway_name       = "example"
  gateway_timezone   = "GMT"
  gateway_type       = "CACHED"
}

resource "aws_storagegateway_cache" "example" {
  disk_id     = data.aws_storagegateway_local_disk.example.id
  gateway_arn = aws_storagegateway_gateway.example.arn
}

data "aws_storagegateway_local_disk" "example" {
  
  gateway_arn = aws_storagegateway_gateway.example.arn
}

resource "aws_storagegateway_cached_iscsi_volume" "example" {
  gateway_arn          = aws_storagegateway_cache.example.gateway_arn
  network_interface_id = aws_instance.ha-nodes-1.private_ip
  target_name          = "example"
  volume_size_in_bytes = 10
}
