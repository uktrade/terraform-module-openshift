data "template_file" "nfs-cloudinit" {
  template = "${file("${path.module}/nfs-cloudinit.yml")}"

  vars {
    openshift_url = "${var.openshift["url"]}"
    dns_zone_id = "${var.vpc_conf["zone_id"]}"
    aws_region = "${var.vpc_conf["region"]}"
    cluster_id = "${var.openshift["domain"]}"
    cluster_env = "${var.openshift["environment"]}"
  }
}

resource "aws_ebs_volume" "nfs" {
  count = "${length(split(",", var.aws_conf["availability_zones"]))}"
  availability_zone = "${element(split(",", var.aws_conf["availability_zones"]), count.index)}"
  type = "io1"
  size = 500
  iops = 20000
  encrypted = true
  kms_key_id = "${aws_kms_key.ebs.arn}"

  tags {
    Name = "${var.openshift["domain"]}-nfs"
    Stack = "${var.openshift["domain"]}"
    clusterid = "${var.openshift["domain"]}"
    environment = "${var.openshift["environment"]}"
    host-type = "nfs"
    sub-host-type = "infra"
    region = "${var.vpc_conf["region"]}"
    svc = "nfs"
  }

  lifecycle {
    prevent_destroy = true
    ignore_changes = ["*"]
  }
}

resource "aws_launch_configuration" "nfs" {
  name_prefix = "${var.aws_conf["domain"]}-nfs-"
  image_id = "${data.aws_ami.default.id}"
  instance_type = "${var.aws_conf["instance_type"]}"
  key_name = "${var.aws_conf["key_name"]}"
  iam_instance_profile = "${aws_iam_instance_profile.node-profile.id}"
  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.nfs.id}",
    "${aws_security_group.node-nfs.id}"
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 80
    delete_on_termination = false
  }
  user_data = "${data.template_file.nfs-cloudinit.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "nfs" {
  name = "${var.openshift["domain"]}-nfs"
  launch_configuration = "${aws_launch_configuration.nfs.name}"
  vpc_zone_identifier = ["${split(",", var.vpc_conf["subnets_public"])}"]
  min_size = "${length(split(",", var.vpc_conf["availability_zones"]))}"
  max_size = "${length(split(",", var.vpc_conf["availability_zones"]))}"
  desired_capacity = "${length(split(",", var.vpc_conf["availability_zones"]))}"
  wait_for_capacity_timeout = 0

  tag {
    key = "Name"
    value = "${var.openshift["domain"]}-nfs"
    propagate_at_launch = true
  }
  tag {
    key = "Stack"
    value = "${var.openshift["domain"]}"
    propagate_at_launch = true
  }
  tag {
    key = "clusterid"
    value = "${var.openshift["domain"]}"
    propagate_at_launch = true
  }
  tag {
    key = "KubernetesCluster"
    value = "${var.openshift["domain"]}"
    propagate_at_launch = true
  }
  tag {
    key = "environment"
    value = "${var.openshift["environment"]}"
    propagate_at_launch = true
  }
  tag {
    key = "host-type"
    value = "nfs"
    propagate_at_launch = true
  }
  tag {
    key = "sub-host-type"
    value = "infra"
    propagate_at_launch = true
  }
  tag {
    key = "region"
    value = "infra"
    propagate_at_launch = true
  }
  tag {
    key = "svc"
    value = "nfs"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
