resource "aws_security_group" "master" {
  name = "${var.aws_conf["domain"]}-master"
  vpc_id = "${var.vpc_conf["id"]}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  tags {
    Name = "${var.aws_conf["domain"]}-master"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-master" {
  name = "${var.aws_conf["domain"]}-node-master"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.node.id}", "${aws_security_group.router.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-node-master"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "external-master" {
  name = "${var.aws_conf["domain"]}-external-master"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 8053
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 8053
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.master-elb.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-external-master"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master-elb" {
  name = "${var.openshift["domain"]}-master-elb"
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
    Name = "${var.openshift["domain"]}-master-elb"
    Stack = "${var.openshift["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
