#For creating Public key

resource "aws_key_pair" "tf_key" {
  key_name   = "tf_key"
  public_key = tls_private_key.rsa.public_key_openssh

}

#For creating private key
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#for saving private in local file i.e tfkey
resource "local_file" "tf_key" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "tfkey"
}

#To create AWS instance

resource "aws_instance" "web" {
  ami             = "ami-0ccabb5f82d4c9af5" # ami ID 
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.tf_sg.name]
  key_name        = "tf_key"
  tags = {
    Name = "first-tf-instance"
  }
}

# to create Security Group

resource "aws_security_group" "tf_sg" {
  name        = "security using terraform"
  description = "security using terraform"
  vpc_id      = "vpc-01db598b0ea03322d"

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "tf_sg"
  }
}
