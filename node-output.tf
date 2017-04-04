data "template_file" "node-output-cloudinit" {
  template = "${file("${path.module}/node-cloudinit.yml")}"

  vars {
    openshift_url = "${var.openshift["url"]}"
    dns_zone_id = "${var.vpc_conf["zone_id"]}"
    aws_region = "${var.vpc_conf["region"]}"
    ansible_repo = "${var.openshift["ansible_repo"]}"
    ansible_repo_branch = "${var.openshift["ansible_repo_branch"]}"
    cluster_id = "${replace(var.openshift["domain"], ".", "_")}"
    cluster_env = "${var.openshift["environment"]}"
    openshift_version = "${var.openshift["version"]}"
    openshift_domain = "${var.openshift["domain"]}"
    github_org = "${var.openshift["github_org"]}"
    github_client_id = "${var.openshift["github_client_id"]}"
    github_client_secret = "${var.openshift["github_client_secret"]}"
    aws_access_key = "${aws_iam_access_key.node-user.id}"
    aws_secret_key = "${aws_iam_access_key.node-user.secret}"
    ssh_key = "${replace(file(var.openshift["ssh_key"]), "\n", "\\n")}"
    openshift_asg = "${var.openshift["domain"]}-node-output"
  }
}

resource "aws_launch_configuration" "node-output" {
  name_prefix = "${var.aws_conf["domain"]}-node-output-"
  image_id = "${data.aws_ami.default.id}"
  instance_type = "${var.openshift["compute_instance_type"]}"
  key_name = "${var.aws_conf["key_name"]}"
  iam_instance_profile = "${aws_iam_instance_profile.node-output-profile.id}"
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
  user_data = "${data.template_file.node-output-cloudinit.rendered}"
  associate_public_ip_address = "${lookup(var.public_ip, var.openshift["internal"])}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "node-output" {
  name = "${var.openshift["domain"]}-node-output"
  launch_configuration = "${aws_launch_configuration.node-output.name}"
  vpc_zone_identifier = ["${split(",", var.vpc_conf[lookup(var.subnet-type, var.openshift["internal"])])}"]
  min_size = "${var.openshift["node_capacity_min"]}"
  max_size = "${var.openshift["node_capacity_max"]}"
  desired_capacity = "${var.openshift["node_capacity_min"]}"
  wait_for_capacity_timeout = 0

  tag {
    key = "Name"
    value = "${var.openshift["domain"]}-node-output"
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
    value = "primary"
    propagate_at_launch = true
  }
  tag {
    key = "svc"
    value = "node"
    propagate_at_launch = true
  }
  tag {
    key = "process-type"
    value = "output"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "node-output" {
  name = "${var.openshift["domain"]}-node-output"
  autoscaling_group_name = "${aws_autoscaling_group.node-output.name}"
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
