data "aws_route53_zone" "my_route53_zone" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "apigw_alias" {
  zone_id = data.aws_route53_zone.my_route53_zone.zone_id
  name    = "gitbot.${data.aws_route53_zone.my_route53_zone.name}"
  type    = "A"

  alias {
    name                   = aws_apigatewayv2_domain_name.domain.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.domain.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}