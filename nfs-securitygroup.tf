resource "aws_security_group" "nfs" {
  name = "${var.aws_conf["domain"]}-nfs"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    self = true
  }

  tags {
    Name = "${var.aws_conf["domain"]}-nfs"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-nfs" {
  name = "${var.aws_conf["domain"]}-node-nfs"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.master.id}", "${aws_security_group.node.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-node-nfs"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
