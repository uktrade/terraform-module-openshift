resource "aws_iam_role" "node-compute-role" {
  name = "${var.openshift["domain"]}-openshift-node-compute-role"
  assume_role_policy = "${file("${path.module}/policies/default-role.json")}"
}

resource "aws_iam_role_policy" "node-compute-default-policy" {
  name = "${var.openshift["domain"]}-compute-default-policy"
  policy = "${file("${path.module}/policies/default-policy.json")}"
  role = "${aws_iam_role.node-compute-role.id}"
}

resource "aws_iam_role_policy" "node-compute-ebs-policy" {
  name = "${var.openshift["domain"]}-compute-ebs-policy"
  policy = "${data.template_file.node-ebs-policy.rendered}"
  role = "${aws_iam_role.node-compute-role.id}"
}

resource "aws_iam_instance_profile" "node-compute-profile" {
  name = "${var.openshift["domain"]}-compute-profile"
  path = "/"
  role = "${aws_iam_role.node-compute-role.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "route53-compute" {
  name = "${var.openshift["domain"]}-compute-route53-policy"
  policy = "${data.template_file.route53_policy.rendered}"
  role = "${aws_iam_role.node-compute-role.name}"
}

resource "aws_iam_role_policy" "compute-kms-policy" {
  name = "${var.openshift["domain"]}-compute-kms-policy"
  policy = "${data.template_file.role-kms.rendered}"
  role = "${aws_iam_role.node-compute-role.id}"
}

data "template_file" "datastore-compute-input-policy" {
  template = "${file("${path.module}/policies/s3-ro-policy.json")}"

  vars {
    s3 = "${aws_s3_bucket.datastore-input.id}"
  }
}

resource "aws_iam_role_policy" "datastore-compute-input-policy" {
  name = "${var.openshift["domain"]}-input-datastore-policy"
  policy = "${data.template_file.datastore-compute-input-policy.rendered}"
  role = "${aws_iam_role.node-compute-role.id}"
}

data "template_file" "datastore-compute-output-policy" {
  template = "${file("${path.module}/policies/s3-rw-policy.json")}"

  vars {
    s3 = "${aws_s3_bucket.datastore-output.id}"
  }
}

resource "aws_iam_role_policy" "datastore-compute-output-policy" {
  name = "${var.openshift["domain"]}-output-datastore-policy"
  policy = "${data.template_file.datastore-compute-output-policy.rendered}"
  role = "${aws_iam_role.node-compute-role.id}"
}
