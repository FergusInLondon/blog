data "cloudflare_zones" "blog_cf_zone" {
  filter {
    name = "fergus.london"
  }
}

resource "cloudflare_record" "blog_dns_record" {
  zone_id         = data.cloudflare_zones.blog_cf_zone.zones[0].id
  name            = "blog"
  content         = cloudflare_pages_project.blog_pages_project.subdomain
  type            = "CNAME"
  proxied         = true
  ttl             = 1
  allow_overwrite = true
}
