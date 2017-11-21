resource "aws_security_group" "node" {
  name = "${var.aws_conf["domain"]}-node"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.node-compute.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-node"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-compute" {
  name = "${var.aws_conf["domain"]}-compute"
  vpc_id = "${var.vpc_conf["id"]}"

  tags {
    Name = "${var.aws_conf["domain"]}-compute"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-input" {
  name = "${var.aws_conf["domain"]}-input"
  vpc_id = "${var.vpc_conf["id"]}"

  tags {
    Name = "${var.aws_conf["domain"]}-input"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-output" {
  name = "${var.aws_conf["domain"]}-output"
  vpc_id = "${var.vpc_conf["id"]}"

  tags {
    Name = "${var.aws_conf["domain"]}-output"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master-node" {
  name = "${var.aws_conf["domain"]}-master-node"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.master.id}", "${aws_security_group.router.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-master-node"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
