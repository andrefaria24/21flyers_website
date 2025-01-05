resource "aws_vpc" "vpc" {
  cidr_block = "10.21.1.0/24"

  tags = {
    "Name"    = "vpc-21flyers"
    "Purpose" = "21 Flyers"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.21.1.0/28"

  tags = {
    "Name"    = "sub-21flyers"
    "Purpose" = "21 Flyers"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name"    = "igw-21flyers"
    "Purpose" = "21 Flyers"
  }
}

resource "aws_ec2_managed_prefix_list" "cloudflare" {
  name           = "Cloudflare CIDRs"
  address_family = "IPv4"
  max_entries    = 30

  dynamic "entry" {
    for_each = jsondecode(file("${path.module}/files/cloudflare_ip.txt"))

    content {
      cidr = entry.value
    }
  }

  tags = {
    "Last Modified" = "01/04/2025"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "10.21.1.0/24"
    gateway_id = "local"
  }

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# resource "aws_route_table_association" "web_subnet" {
#   subnet_id      = aws_subnet.web_subnet.id
#   route_table_id = aws_route_table.route_table.id
# }

resource "aws_security_group" "allow_ssh" {
  name        = "21flyers-web-ssh"
  description = "SSH Access"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Purpose = "21 Flyers"
  }
}

resource "aws_security_group" "allow_http" {
  name        = "21flyers-web-http"
  description = "HTTP Access"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Purpose = "21 Flyers"
  }
}

resource "aws_security_group" "allow_https" {
  name        = "21flyers-web-https"
  description = "HTTPS Access"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    Purpose = "21 Flyers"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.allow_ssh.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.home_ip
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.allow_http.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  prefix_list_id    = aws_ec2_managed_prefix_list.cloudflare.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.allow_https.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = aws_ec2_managed_prefix_list.cloudflare.id
}

resource "aws_instance" "web_server" {
  ami                         = "ami-08eb4db5a75153599"
  instance_type               = "t4g.nano"
  associate_public_ip_address = true

  tags = {
    "Name" = "prod-21flyers"
  }
}