provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "main" {
  cidr_block           = "${var.cidr}"
  enable_dns_support   = "${var.enable_dns_support}"
  enable_dns_hostnames = "${var.enable_dns_hostnames}"

  tags {
    Name        = "Main"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Main VPC"
    Provisioner = "Terraform"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    Name        = "Main"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Main Internet Gateway"
    Provisioner = "Terraform"
  }
}

resource "aws_eip" "nat" {
  vpc = true

  tags {
    Name        = "Nat"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "NAT EIP"
    Provisioner = "Terraform"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.main"]

  tags {
    Name        = "Main"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Main NAT Gateway"
    Provisioner = "Terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${element(var.public_cidrs, count.index)}"
  availability_zone       = "${element(var.azs, count.index)}"
  count                   = "${length(var.public_cidrs)}"
  map_public_ip_on_launch = true

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "Public Subnet"
    App         = "WebApp"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Public Subnet"
    Provisioner = "Terraform"
  }
}

# Routes
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"
  count  = "${length(var.public_cidrs)}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main.id}"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "Public Route Table"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Public Route Table"
    Provisioner = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
  count          = "${length(var.public_cidrs)}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route" "igw" {
  route_table_id         = "${element(aws_route_table.public.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
  count                  = "${length(var.public_cidrs)}"

  depends_on = [
    "aws_route_table.public",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "${var.private_cidr}"
  map_public_ip_on_launch = false

  tags {
    Name        = "Private Subnet "
    App         = "MySQL"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Private Subnet"
    Provisioner = "Terraform"
  }
}

// Private route table
resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.main.id}"
  }

  depends_on = [
    "aws_route_table.public",
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags {
    Name        = "Private Route Table"
    App         = "MySQL"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Private Route Table"
    Provisioner = "Terraform"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = "${aws_subnet.private.id}"
  route_table_id = "${aws_route_table.private.id}"

  lifecycle {
    create_before_destroy = true
  }
}

//Security Groups

resource "aws_security_group" "WebSG" {
  name        = "WebSG"
  description = "All inboubd traffic from alb"
  vpc_id      = "${aws_vpc.main.id}"
}

resource "aws_security_group" "DbSG" {
  name        = "DbSG"
  description = "Allow inbound traffic from WebSG"
  vpc_id      = "${aws_vpc.main.id}"
}

resource "aws_security_group" "AlbSG" {
  name        = "AlbSG"
  description = "Allow HTTP/HTTPS on ALB"
  vpc_id      = "${aws_vpc.main.id}"
}

// Security group rules

resource "aws_security_group_rule" "SSHWeb" {
  from_port         = 22
  protocol          = "TCP"
  security_group_id = "${aws_security_group.WebSG.id}"
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_security_group_rule" "SSHWebOutbound" {
  from_port         = 22
  protocol          = "TCP"
  security_group_id = "${aws_security_group.WebSG.id}"
  to_port           = 22
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

resource "aws_security_group_rule" "SSHDb" {
  from_port                = 22
  protocol                 = "TCP"
  security_group_id        = "${aws_security_group.DbSG.id}"
  to_port                  = 22
  source_security_group_id = "${aws_security_group.WebSG.id}"
  type                     = "ingress"
}

resource "aws_security_group_rule" "SSHDbOutbound" {
  from_port                = 22
  protocol                 = "TCP"
  security_group_id        = "${aws_security_group.DbSG.id}"
  to_port                  = 22
  source_security_group_id = "${aws_security_group.WebSG.id}"
  type                     = "egress"
}

resource "aws_security_group_rule" "WebInbound1" {
  from_port                = 80
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.AlbSG.id}"
  security_group_id        = "${aws_security_group.WebSG.id}"
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_security_group_rule" "WenInbound2" {
  from_port                = 443
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.AlbSG.id}"
  security_group_id        = "${aws_security_group.WebSG.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "DbInbound" {
  from_port                = 5432
  protocol                 = "TCP"
  source_security_group_id = "${aws_security_group.WebSG.id}"
  security_group_id        = "${aws_security_group.DbSG.id}"
  to_port                  = 5432
  type                     = "ingress"
}

resource "aws_security_group_rule" "DbOutbound" {
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.DbSG.id}"
}

resource "aws_security_group_rule" "WebOutbound1" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.WebSG.id}"
}

resource "aws_security_group_rule" "WebOutbound2" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.WebSG.id}"
}

resource "aws_security_group_rule" "alb1" {
  from_port         = 80
  protocol          = "TCP"
  security_group_id = "${aws_security_group.AlbSG.id}"
  to_port           = 80
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_security_group_rule" "alb2" {
  from_port         = 443
  protocol          = "TCP"
  security_group_id = "${aws_security_group.AlbSG.id}"
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_security_group_rule" "AlbOutbound" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.AlbSG.id}"
}

resource "aws_security_group_rule" "AlbOutbound2" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "TCP"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.AlbSG.id}"
}

//Deploy Instances from the AMI's

resource "aws_instance" "Web" {
  ami             = "${var.web_ami}"
  instance_type   = "t2.micro"
  count           = 1
  key_name        = "sf_testing_key"
  subnet_id       = "${element(aws_subnet.public.*.id, count.index)}"
  security_groups = ["${aws_security_group.WebSG.id}"]

  tags {
    Name        = "WebServer"
    App         = "Nginx"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Service Web Server"
    Provisioner = "Terraform"
  }
}

resource "aws_instance" "Web2" {
  ami             = "${var.web_ami}"
  instance_type   = "t2.micro"
  count           = 1
  key_name        = "sf_testing_key"
  subnet_id       = "${element(aws_subnet.public.*.id, count.index)}"
  security_groups = ["${aws_security_group.WebSG.id}"]

  tags {
    Name        = "WebServer2"
    App         = "Nginx"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Service Web Server"
    Provisioner = "Terraform"
  }
}

resource "aws_instance" "DB" {
  ami             = "${var.db_ami}"
  instance_type   = "t2.micro"
  count           = 1
  security_groups = ["${aws_security_group.DbSG.id}"]
  subnet_id       = "${aws_subnet.private.id}"

  tags {
    Name        = "DBBackend"
    App         = "Postgresql"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Service DB Backend"
    Provisioner = "Terraform"
  }
}

//Create alb s3 bucket

resource "aws_s3_bucket" "AlbLogBucket" {
  bucket = "alb-global-log-fund"
  acl    = "public-read"
}

//Create Application Load Balancer

resource "aws_alb" "main" {
  name            = "ExternalALB"
  subnets         = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.AlbSG.id}"]

  access_logs {
    bucket  = "alb-global-log-fund"
    enabled = "true"
  }

  depends_on = ["aws_alb_target_group.main"]

  tags {
    Name        = "ServiceALB"
    App         = "Web"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Service ALB"
    Provisioner = "Terraform"
  }
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = "${aws_alb.main.arn}"
  port              = "${var.alb_port}"
  protocol          = "${var.alb_protocol}"
  ssl_policy        = "${var.alb_protocol == "HTTPS" ? var.ssl_policy : ""}"
  certificate_arn   = "${var.alb_protocol == "HTTPS" ? var.cert_arn : ""}"
  depends_on        = ["aws_alb.main"]

  default_action {
    target_group_arn = "${aws_alb_target_group.main.id}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "main" {
  name                 = "ServiceALB"
  protocol             = "${var.app_protocol}"
  port                 = "${var.alb_port}"
  vpc_id               = "${aws_vpc.main.id}"
  deregistration_delay = "${var.alb_deregistration_delay}"

  health_check {
    path                = "${var.app_health_check}"
    interval            = "${var.app_health_check_interval}"
    healthy_threshold   = "${var.app_health_check_healthy_threshold}"
    unhealthy_threshold = "${var.app_health_check_unhealthy_threshold}"
  }

  tags {
    Name        = "ExternalALB"
    App         = "Service ALB"
    ManagedBy   = "PetarPeshev"
    Environment = "${var.environment}"
    Role        = "Service ALB target group"
    Provisioner = "Terraform"
  }
}

resource "aws_alb_target_group_attachment" "main" {
  target_group_arn = "${aws_alb_target_group.main.arn}"
  target_id        = "${aws_instance.Web.id}"
  port             = 80
}

resource "aws_alb_target_group_attachment" "main2" {
  target_group_arn = "${aws_alb_target_group.main.arn}"
  target_id        = "${aws_instance.Web2.id}"
  port             = 80
}
