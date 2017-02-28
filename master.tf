data "template_file" "master-cloudinit" {
  template = "${file("./modules/openshift-cluster/master-cloudinit.yml")}"

  vars {
    openshift_url = "${var.openshift["url"]}"
    dns_zone_id = "${var.vpc_conf["zone_id"]}"
    aws_region = "${var.vpc_conf["region"]}"
  }
}

resource "aws_launch_configuration" "master" {
  name_prefix = "${var.openshift["domain"]}-master-"
  image_id = "${data.aws_ami.default.id}"
  instance_type = "${var.aws_conf["instance_type"]}"
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
  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "master" {
  name = "${var.openshift["domain"]}-master"
  launch_configuration = "${aws_launch_configuration.master.name}"
  vpc_zone_identifier = ["${split(",", var.vpc_conf["subnets_public"])}"]
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
    value = "${var.vpc_conf["region"]}"
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

resource "aws_security_group" "master-elb" {
  name = "${var.openshift["domain"]}-master-elb"
  vpc_id = "${var.vpc_conf["id"]}"

  ingress {
    from_port = 0
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "${var.openshift["domain"]}-master-elb"
    Stack = "${var.openshift["domain"]}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "master" {
  name = "master-elb"
  subnets = ["${split(",", var.vpc_conf["subnets_public"])}"]

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
  name = "master-elb-internal"
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
