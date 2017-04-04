resource "aws_security_group" "node-compute" {
  name = "${var.aws_conf["domain"]}-node-compute"
  vpc_id = "${var.vpc_conf["id"]}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.aws_conf["cidr_block"]}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-node"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node" {
  name = "${var.aws_conf["domain"]}-node"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  tags {
    Name = "${var.aws_conf["domain"]}-node"
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
