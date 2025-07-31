variable "vpc_id" {}
variable "public_subnets" {
  type = list(string)
}
variable "alb_security_group_ingress_cidr" {
  default = ["0.0.0.0/0"]
  description = "Who can access the ALB (default: open to all)"
}
variable "ec2_target_ids" {
  type = list(string)
  description = "EC2 instance IDs to register as targets"
}
