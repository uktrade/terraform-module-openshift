resource "aws_iam_role" "node-input-role" {
  name = "${var.openshift["domain"]}-openshift-node-input-role"
  assume_role_policy = "${file("${path.module}/policies/default-role.json")}"
}

resource "aws_iam_role_policy" "node-input-default-policy" {
  name = "${var.openshift["domain"]}-input-default-policy"
  policy = "${file("${path.module}/policies/default-policy.json")}"
  role = "${aws_iam_role.node-input-role.id}"
}

resource "aws_iam_role_policy" "node-input-ebs-policy" {
  name = "${var.openshift["domain"]}-input-ebs-policy"
  policy = "${data.template_file.node-ebs-policy.rendered}"
  role = "${aws_iam_role.node-input-role.id}"
}

resource "aws_iam_instance_profile" "node-input-profile" {
  name = "${var.openshift["domain"]}-input-profile"
  path = "/"
  roles = ["${aws_iam_role.node-input-role.name}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "datastore-input" {
    bucket = "input.${var.openshift["domain"]}"
    acl = "private"

    lifecycle_rule {
      prefix = ""
      enabled = true
      expiration {
        days = 180
      }
      noncurrent_version_expiration {
        days = 180
      }
    }

    tags {
        Name = "input.${var.openshift["domain"]}"
        Stack = "${var.openshift["domain"]}"
    }
}

data "template_file" "datastore-input-policy" {
  template = "${file("${path.module}/policies/s3-ro-policy.json")}"

  vars {
    s3 = "${aws_s3_bucket.datastore-input.id}"
  }
}

resource "aws_iam_role_policy" "datastore-input-policy" {
  name = "${var.openshift["domain"]}-input-datastore-policy"
  policy = "${data.template_file.datastore-input-policy.rendered}"
  role = "${aws_iam_role.node-input-role.id}"
}

resource "aws_iam_role_policy" "route53-input" {
  name = "${var.openshift["domain"]}-input-route53-policy"
  policy = "${data.template_file.route53_policy.rendered}"
  role = "${aws_iam_role.node-input-role.name}"
}

resource "aws_iam_role_policy" "input-kms-policy" {
  name = "${var.openshift["domain"]}-input-kms-policy"
  policy = "${data.template_file.role-kms.rendered}"
  role = "${aws_iam_role.node-input-role.id}"
}
