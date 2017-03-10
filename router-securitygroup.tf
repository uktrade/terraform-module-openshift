resource "aws_security_group" "router" {
  name = "${var.aws_conf["domain"]}-router"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 4789
    to_port = 4789
    protocol = "tcp"
    self = true
  }

  tags {
    Name = "${var.aws_conf["domain"]}-router"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-router" {
  name = "${var.aws_conf["domain"]}-node-router"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 4789
    to_port = 4789
    protocol = "tcp"
    security_groups = ["${aws_security_group.router.id}"]
  }

  ingress {
    from_port = 10250
    to_port = 10250
    protocol = "tcp"
    security_groups = ["${aws_security_group.master.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-node-router"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "external-router" {
  name = "${var.aws_conf["domain"]}-external-router"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-external-router"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "router-elb" {
  name = "${var.openshift["domain"]}-router-elb"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.openshift["domain"]}-router-elb"
    Stack = "${var.openshift["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
