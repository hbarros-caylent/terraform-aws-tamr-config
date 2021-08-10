module "tamr-vm" {
  source = "git::git@github.com:Datatamer/terraform-aws-tamr-vm.git?ref=4.1.0"

  ami                = var.ami_id
  instance_type      = "m4.2xlarge"
  key_name           = module.emr_key_pair.key_pair_key_name
  subnet_id          = var.ec2_subnet_id
  vpc_id             = var.vpc_id
  security_group_ids = module.aws-sg-vm.security_group_ids

  aws_role_name               = "${var.name_prefix}-tamr-ec2-role"
  aws_instance_profile_name   = "${var.name_prefix}-tamrvm-instance-profile"
  aws_emr_creator_policy_name = "${var.name_prefix}-emr-creator-policy"
  s3_policy_arns = [
    module.s3-logs.rw_policy_arn,
    module.s3-data.rw_policy_arn
  ]
  tamr_emr_cluster_ids = [] # leave empty when using ephemeral-spark
  tamr_emr_role_arns = [
    module.emr-hbase.emr_service_role_arn,
    module.emr-hbase.emr_ec2_role_arn
  ]
  emr_abac_valid_tags = var.emr_abac_valid_tags
}


module "aws-vm-sg-ports" {
  source = "git::git@github.com:Datatamer/terraform-aws-tamr-vm.git//modules/aws-security-groups?ref=4.1.0"
  # source = "../../modules/aws-security-groups"
}

module "aws-sg-vm" {
  source              = "git::git@github.com:Datatamer/terraform-aws-security-groups.git?ref=1.0.0"
  vpc_id              = var.vpc_id
  ingress_cidr_blocks = var.ingress_cidr_blocks
  egress_cidr_blocks = [
    "0.0.0.0/0" # TODO: scope down
  ]
  ingress_protocol = "tcp"
  egress_protocol  = "all"
  ingress_ports    = concat(module.aws-vm-sg-ports.ingress_ports, module.sg-ports-es.ingress_ports)
  sg_name_prefix   = format("%s-%s", var.name_prefix, "tamr-vm")
  tags             = var.tags
}
