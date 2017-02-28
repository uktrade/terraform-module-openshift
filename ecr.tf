resource "aws_ecr_repository" "registry" {
  name = "registry.${var.openshift["domain"]}"
}

data "template_file" "registry-policy" {
  template = "${file("policies/ecr-policy.json")}"

  vars {
    role = "${aws_iam_role.node-role.arn}"
  }
}

resource "aws_ecr_repository_policy" "registry-policy" {
  repository = "${aws_ecr_repository.registry.name}"
  policy = "${data.template_file.registry-policy.rendered}"
}

resource "aws_route53_record" "registry-dns" {
   zone_id = "${var.vpc_conf["zone_id"]}"
   name = "registry.${var.openshift["domain"]}"
   type = "CNAME"
   ttl = 60
   records = ["${element(split("/", aws_ecr_repository.registry.repository_url), 0)}"]

   lifecycle {
     create_before_destroy = true
   }
}
