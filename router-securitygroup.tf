resource "aws_security_group" "router" {
  name = "${var.aws_conf["domain"]}-router"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.master.id}", "${aws_security_group.node.id}"]
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
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
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
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
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
