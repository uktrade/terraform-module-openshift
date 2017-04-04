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
  roles = ["${aws_iam_role.node-compute-role.name}"]

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
