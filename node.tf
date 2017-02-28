data "template_file" "node-cloudinit" {
  template = "${file("${path.module}/node-cloudinit.yml")}"

  vars {
    openshift_url = "${var.openshift["url"]}"
    dns_zone_id = "${var.vpc_conf["zone_id"]}"
    aws_region = "${var.vpc_conf["region"]}"
  }
}

resource "aws_launch_configuration" "node" {
  name_prefix = "${var.aws_conf["domain"]}-node-"
  image_id = "${data.aws_ami.default.id}"
  instance_type = "${var.aws_conf["instance_type"]}"
  key_name = "${var.aws_conf["key_name"]}"
  iam_instance_profile = "${aws_iam_instance_profile.node-profile.id}"
  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.node.id}",
    "${aws_security_group.master-node.id}"
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 200
    delete_on_termination = false
  }
  user_data = "${data.template_file.node-cloudinit.rendered}"
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node" {
  name = "${var.openshift["domain"]}-node"
  launch_configuration = "${aws_launch_configuration.node.name}"
  vpc_zone_identifier = ["${split(",", var.vpc_conf["subnets_public"])}"]
  min_size = "${var.openshift["node_capacity_min"]}"
  max_size = "${var.openshift["node_capacity_max"]}"
  desired_capacity = "${var.openshift["node_capacity_min"]}"
  wait_for_capacity_timeout = 0

  tag {
    key = "Name"
    value = "${var.openshift["domain"]}-node"
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
    key = "environment"
    value = "${var.openshift["environment"]}"
    propagate_at_launch = true
  }
  tag {
    key = "host-type"
    value = "node"
    propagate_at_launch = true
  }
  tag {
    key = "sub-host-type"
    value = "compute"
    propagate_at_launch = true
  }
  tag {
    key = "region"
    value = "${var.vpc_conf["region"]}"
    propagate_at_launch = true
  }
  tag {
    key = "svc"
    value = "node"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "node" {
  name = "${var.openshift["domain"]}-node"
  autoscaling_group_name = "${aws_autoscaling_group.node.name}"
  adjustment_type = "ChangeInCapacity"
  metric_aggregation_type = "Maximum"
  policy_type = "StepScaling"
  step_adjustment {
    metric_interval_lower_bound = 3.0
    scaling_adjustment = 2
  }
  step_adjustment {
    metric_interval_lower_bound = 2.0
    metric_interval_upper_bound = 3.0
    scaling_adjustment = 2
  }
  step_adjustment {
    metric_interval_lower_bound = 1.0
    metric_interval_upper_bound = 2.0
    scaling_adjustment = -1
  }

  lifecycle {
    create_before_destroy = true
  }
}
