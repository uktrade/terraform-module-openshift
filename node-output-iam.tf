resource "aws_iam_role" "node-output-role" {
  name = "${var.openshift["domain"]}-openshift-node-output-role"
  assume_role_policy = "${file("${path.module}/policies/default-role.json")}"
}

resource "aws_iam_role_policy" "node-output-default-policy" {
  name = "${var.openshift["domain"]}-output-default-policy"
  policy = "${file("${path.module}/policies/default-policy.json")}"
  role = "${aws_iam_role.node-output-role.id}"
}

resource "aws_iam_role_policy" "node-output-ebs-policy" {
  name = "${var.openshift["domain"]}-output-ebs-policy"
  policy = "${data.template_file.node-ebs-policy.rendered}"
  role = "${aws_iam_role.node-output-role.id}"
}

resource "aws_iam_instance_profile" "node-output-profile" {
  name = "${var.openshift["domain"]}-output-profile"
  path = "/"
  roles = ["${aws_iam_role.node-output-role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "datastore-output" {
    bucket = "output.${var.openshift["domain"]}"
    acl = "private"

    lifecycle_rule {
      id = "6-months-cleanup"
      prefix = ""
      enabled = true
      expiration {
        days = 180
      }
    }

    tags {
        Name = "output.${var.openshift["domain"]}"
        Stack = "${var.openshift["domain"]}"
    }
}

data "template_file" "datastore-output-policy" {
  template = "${file("${path.module}/policies/s3-policy.json")}"

  vars {
    s3 = "${aws_s3_bucket.datastore-output.id}"
  }
}

resource "aws_iam_role_policy" "datastore-output-policy" {
  name = "${var.openshift["domain"]}-output-datastore-policy"
  policy = "${data.template_file.datastore-output-policy.rendered}"
  role = "${aws_iam_role.node-output-role.id}"
}

resource "aws_iam_role_policy" "route53-output" {
  name = "${var.openshift["domain"]}-output-route53-policy"
  policy = "${data.template_file.route53_policy.rendered}"
  role = "${aws_iam_role.node-output-role.name}"
}

resource "aws_iam_role_policy" "output-kms-policy" {
  name = "${var.openshift["domain"]}-output-kms-policy"
  policy = "${data.template_file.role-kms.rendered}"
  role = "${aws_iam_role.node-output-role.id}"
}
