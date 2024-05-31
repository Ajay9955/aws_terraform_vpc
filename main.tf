provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "mysub1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "mysub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
}
resource "aws_route_table_association" "myrtas1" {
  route_table_id = aws_route_table.myrt.id
  subnet_id      = aws_subnet.mysub1.id
}

resource "aws_route_table_association" "myrtas2" {
  route_table_id = aws_route_table.myrt.id
  subnet_id      = aws_subnet.mysub2.id
}

resource "aws_security_group" "mysg" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "myins1" {
  ami             = "ami-04b70fa74e45c3917"
  security_groups = [aws_security_group.mysg.id]
  subnet_id       = aws_subnet.mysub1.id
  instance_type   = "t2.micro"
  key_name = "ajay_instance1" ## provide ur key-value pair name here
  user_data = base64encode(file("file1.sh"))
}

resource "aws_instance" "myins2" {
  ami             = "ami-04b70fa74e45c3917"
  security_groups = [aws_security_group.mysg.id]
  subnet_id       = aws_subnet.mysub2.id
  instance_type   = "t2.micro"
  key_name = "ajay_instance1" ## provide ur key-value pair name
  user_data = base64encode(file("file2.sh"))
}

resource "aws_lb" "myalb" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.mysg.id]
  subnets            = [aws_subnet.mysub1.id, aws_subnet.mysub2.id]
}

resource "aws_lb_target_group" "mytg" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-209"
  }
}

resource "aws_lb_target_group_attachment" "tga1" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.myins1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tga2" {
  target_group_arn = aws_lb_target_group.mytg.arn
  target_id        = aws_instance.myins2.id
  port             = 80
}

resource "aws_lb_listener" "name" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mytg.id
  }
}