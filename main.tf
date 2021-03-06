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

variable "subnet-type" {
  default = {
    "true" = "subnets_private"
    "false" = "subnets_public"
  }
}

variable "public_ip" {
  default = {
    "true" = "false"
    "false" = "true"
  }
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

resource "aws_iam_user" "node-user" {
    name = "${var.openshift["domain"]}-openshift-user"
}

resource "aws_iam_access_key" "node-user" {
  user = "${aws_iam_user.node-user.name}"
}

resource "aws_iam_role" "node-role" {
  name = "${var.openshift["domain"]}-openshift-role"
  assume_role_policy = "${file("${path.module}/policies/default-role.json")}"
}

resource "aws_iam_user_policy" "user-default-policy" {
  name = "${var.openshift["domain"]}-user-default-policy"
  policy = "${file("${path.module}/policies/default-policy.json")}"
  user = "${aws_iam_user.node-user.name}"
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

resource "aws_iam_user_policy" "user-ebs-policy" {
  name = "${var.openshift["domain"]}-user-ebs-policy"
  policy = "${data.template_file.node-ebs-policy.rendered}"
  user = "${aws_iam_user.node-user.name}"
}

resource "aws_iam_role_policy" "node-ebs-policy" {
  name = "${var.openshift["domain"]}-openshift-ebs-policy"
  policy = "${data.template_file.node-ebs-policy.rendered}"
  role = "${aws_iam_role.node-role.id}"
}

resource "aws_iam_instance_profile" "node-profile" {
  name = "${var.openshift["domain"]}-openshift-profile"
  path = "/"
  role = "${aws_iam_role.node-role.name}"

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

resource "aws_iam_user_policy" "user-datastore-policy" {
  name = "${var.openshift["domain"]}-user-datastore-policy"
  policy = "${data.template_file.datastore-policy.rendered}"
  user = "${aws_iam_user.node-user.name}"
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

resource "aws_iam_user_policy" "user-route53-policy" {
  name = "${var.openshift["domain"]}-user-route53-policy"
  policy = "${data.template_file.route53_policy.rendered}"
  user = "${aws_iam_user.node-user.name}"
}

resource "aws_iam_role_policy" "route53" {
  name = "${var.openshift["domain"]}-openshift-route53-policy"
  policy = "${data.template_file.route53_policy.rendered}"
  role = "${aws_iam_role.node-role.name}"
}

resource "aws_kms_key" "ebs" {
  description = "${var.openshift["domain"]} NFS EBS Key"
}

data "template_file" "role-kms" {
  template = "${file("${path.module}/policies/role-kms-policy.json")}"

  vars {
    aws_region = "${var.aws_conf["region"]}"
    aws_account_id = "${var.aws_conf["account_id"]}"
    ebs_kms_arn = "${aws_kms_key.ebs.arn}"
  }
}

resource "aws_iam_user_policy" "user-kms-policy" {
  name = "${var.openshift["domain"]}-user-kms-policy"
  policy = "${data.template_file.role-kms.rendered}"
  user = "${aws_iam_user.node-user.name}"
}

resource "aws_iam_role_policy" "role-kms-policy" {
  name = "${var.openshift["domain"]}-openshift-kms-policy"
  policy = "${data.template_file.role-kms.rendered}"
  role = "${aws_iam_role.node-role.id}"
}
