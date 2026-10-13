# DNS failover. The primary record answers while the health check passes.
# When the health check fails, Route 53 starts answering with the secondary
# record that points at the DR region. DNS failover moves traffic, it does not
# fix data: the failover playbook still has to promote the replica first.

data "aws_route53_zone" "app" {
  name = var.hosted_zone_name
}

resource "aws_route53_health_check" "primary" {
  fqdn              = var.app_primary_endpoint
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "${var.project}-primary-health"
  }
}

resource "aws_route53_record" "primary" {
  zone_id        = data.aws_route53_zone.app.zone_id
  name           = var.app_domain
  type           = "A"
  ttl            = 60
  set_identifier = "primary"

  failover_routing_policy {
    type = "PRIMARY"
  }

  health_check_id = aws_route53_health_check.primary.id
  records         = [var.app_primary_ip]
}

resource "aws_route53_record" "secondary" {
  zone_id        = data.aws_route53_zone.app.zone_id
  name           = var.app_domain
  type           = "A"
  ttl            = 60
  set_identifier = "secondary"

  failover_routing_policy {
    type = "SECONDARY"
  }

  records = [var.app_dr_ip]
}
