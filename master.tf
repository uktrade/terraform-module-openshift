data "template_file" "master-cloudinit" {
  template = "${file("${path.module}/master-cloudinit.yml")}"

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
    openshift_asg = "${var.openshift["domain"]}-master"
  }
}

resource "aws_launch_configuration" "master" {
  name_prefix = "${var.openshift["domain"]}-master-"
  image_id = "${data.aws_ami.default.id}"
  instance_type = "${var.aws_conf["master_instance_type"]}"
  key_name = "${var.aws_conf["key_name"]}"
  iam_instance_profile = "${aws_iam_instance_profile.node-profile.id}"
  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.master.id}",
    "${aws_security_group.node-master.id}",
    "${aws_security_group.external-master.id}"
  ]
  root_block_device {
    volume_type = "gp2"
    volume_size = 200
    delete_on_termination = false
  }
  user_data = "${data.template_file.master-cloudinit.rendered}"
  associate_public_ip_address = "${lookup(var.public_ip, var.openshift["internal"])}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "master" {
  name = "${var.openshift["domain"]}-master"
  launch_configuration = "${aws_launch_configuration.master.name}"
  vpc_zone_identifier = ["${split(",", var.vpc_conf[lookup(var.subnet-type, var.openshift["internal"])])}"]
  min_size = "${var.openshift["master_capacity_min"]}"
  max_size = "${var.openshift["master_capacity_max"]}"
  desired_capacity = "${var.openshift["master_capacity_min"]}"
  wait_for_capacity_timeout = 0
  load_balancers = [
    "${aws_elb.master.id}",
    "${aws_elb.master-internal.id}"
  ]

  tag {
    key = "Name"
    value = "${var.openshift["domain"]}-master"
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
    value = "master"
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
    value = "master"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "master" {
  name = "${var.openshift["domain"]}-master"
  autoscaling_group_name = "${aws_autoscaling_group.master.name}"
  adjustment_type = "ChangeInCapacity"
  metric_aggregation_type = "Maximum"
  policy_type = "StepScaling"
  step_adjustment {
    metric_interval_lower_bound = 2.0
    scaling_adjustment = 1
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

resource "aws_cloudwatch_metric_alarm" "master" {
  alarm_name = "${var.openshift["domain"]}-master"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "80"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.master.name}"
  }
  alarm_actions = ["${aws_autoscaling_policy.master.arn}"]
}

resource "aws_elb" "master" {
  name = "${element(split(".", var.openshift["domain"]), 0)}-master-elb"
  subnets = ["${split(",", var.vpc_conf[lookup(var.subnet-type, var.openshift["internal"])])}"]

  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.master-elb.id}"
  ]

  listener {
    lb_port            = 443
    lb_protocol        = "tcp"
    instance_port      = 443
    instance_protocol  = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 10
    target              = "TCP:443"
    interval            = 30
  }

  connection_draining = true
  cross_zone_load_balancing = true
  internal = "${var.openshift["internal"]}"

  tags {
    Stack = "${var.openshift["domain"]}"
    Name = "${var.openshift["domain"]}-master-elb"
  }
}

resource "aws_elb" "master-internal" {
  name = "${element(split(".", var.openshift["domain"]), 0)}-master-elb-internal"
  subnets = ["${split(",", var.vpc_conf["subnets_private"])}"]

  security_groups = [
    "${var.vpc_conf["security_group"]}",
    "${aws_security_group.master-elb.id}"
  ]

  listener {
    lb_port            = 443
    lb_protocol        = "tcp"
    instance_port      = 443
    instance_protocol  = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 10
    target              = "TCP:443"
    interval            = 30
  }

  connection_draining = true
  cross_zone_load_balancing = true
  internal = true

  tags {
    Stack = "${var.openshift["domain"]}"
    Name = "${var.openshift["domain"]}-master-elb"
  }
}

resource "aws_route53_record" "master" {
   zone_id = "${var.vpc_conf["zone_id"]}"
   name = "${var.openshift["master_domain"]}"
   type = "A"
   alias {
     name = "${aws_elb.master.dns_name}"
     zone_id = "${aws_elb.master.zone_id}"
     evaluate_target_health = false
   }

   lifecycle {
     create_before_destroy = true
   }
}

resource "aws_route53_record" "master-internal" {
   zone_id = "${var.vpc_conf["zone_id"]}"
   name = "master.${var.openshift["domain"]}"
   type = "A"
   alias {
     name = "${aws_elb.master-internal.dns_name}"
     zone_id = "${aws_elb.master-internal.zone_id}"
     evaluate_target_health = false
   }

   lifecycle {
     create_before_destroy = true
   }
}
