resource "aws_security_group" "node" {
  name = "${var.aws_conf["domain"]}-node"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 4789
    to_port = 4789
    protocol = "tcp"
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
    Name = "${var.aws_conf["domain"]}-master-node"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
