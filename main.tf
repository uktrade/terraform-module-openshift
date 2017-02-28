variable "aws_conf" {
  type = "map"
  default = {}
}

variable "vpc_conf" {
  type = "map"
  default = {}
}

variable "openshift" {
  default = {}
}

data "aws_ami" "default" {
  most_recent = true
  name_regex = "CentOS Linux 7 x86_64 HVM EBS"
  filter {
    name = "owner-alias"
    values = ["aws-marketplace"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_iam_role" "node-role" {
  name = "${var.openshift["domain"]}-openshift-role"
  assume_role_policy = "${file("${path.module}/policies/default-role.json")}"
}

resource "aws_iam_role_policy" "node-default-policy" {
  name = "${var.openshift["domain"]}-openshift-default-policy"
  policy = "${file("${path.module}/policies/default-policy.json")}"
  role = "${aws_iam_role.node-role.id}"
}

data "template_file" "node-ebs-policy" {
  template = "${file("${path.module}/policies/ec2-ebs-policy.json")}"

  vars {
    region = "${var.vpc_conf["region"]}"
    account = "${var.aws_conf["account_id"]}"
    vpc = "${var.vpc_conf["id"]}"
  }
}

resource "aws_iam_role_policy" "node-ebs-policy" {
  name = "${var.openshift["domain"]}-openshift-ebs-policy"
  policy = "${data.template_file.node-ebs-policy.rendered}"
  role = "${aws_iam_role.node-role.id}"
}

resource "aws_iam_instance_profile" "node-profile" {
  name = "${var.openshift["domain"]}-openshift-profile"
  path = "/"
  roles = ["${aws_iam_role.node-role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "datastore" {
    bucket = "datastore.${var.openshift["domain"]}"
    acl = "private"

    tags {
        Name = "datastore.${var.openshift["domain"]}"
        Stack = "${var.openshift["domain"]}"
    }
}

data "template_file" "datastore-policy" {
  template = "${file("${path.module}/policies/s3-policy.json")}"

  vars {
    s3 = "${aws_s3_bucket.datastore.id}"
  }
}

resource "aws_iam_role_policy" "datastore-policy" {
  name = "${var.openshift["domain"]}-openshift-datastore-policy"
  policy = "${data.template_file.datastore-policy.rendered}"
  role = "${aws_iam_role.node-role.id}"
}

data "template_file" "route53_policy" {
  template = "${file("${path.module}/policies/route53-policy.json")}"

  vars {
    zone_id = "${var.vpc_conf["zone_id"]}"
  }
}

resource "aws_iam_role_policy" "route53" {
  name = "${var.openshift["domain"]}-openshift-route53-policy"
  policy = "${data.template_file.route53_policy.rendered}"
  role = "${aws_iam_role.node-role.name}"
}
