output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
  description = "Public DNS to access the application"
}
