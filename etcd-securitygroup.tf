resource "aws_security_group" "etcd" {
  name = "${var.aws_conf["domain"]}-etcd"
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
    Name = "${var.aws_conf["domain"]}-etcd"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node-etcd" {
  name = "${var.aws_conf["domain"]}-node-etcd"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = ["${aws_security_group.master.id}", "${aws_security_group.node.id}", "${aws_security_group.router.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-node-etcd"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "internal-etcd" {
  name = "${var.aws_conf["domain"]}-internal-etcd"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 2379
    protocol = "tcp"
    security_groups = ["${aws_security_group.etcd-elb.id}"]
  }

  ingress {
    from_port = 0
    to_port = 2380
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.etcd-elb.id}"]
  }

  tags {
    Name = "${var.aws_conf["domain"]}-internal-etcd"
    Stack = "${var.aws_conf["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "etcd-elb" {
  name = "${var.openshift["domain"]}-etcd-elb"
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
    Name = "${var.openshift["domain"]}-etcd-elb"
    Stack = "${var.openshift["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}
