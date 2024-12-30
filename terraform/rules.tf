# Note: The endpoint for PageRules does not yet support "Account Owned
# Tokens". So this means that the API tokens used by Terraform MUST be
# User Owned currently... as I learnt after an hour of frustration.
# (30/12/2024)
#
# It's recent enough that there's no Google results for it, but it looks
#  like this:
#
# and can be fixed by using an user owned token (via the user settings of
# the admin console).
#
# @see https://blog.cloudflare.com/account-owned-tokens-automated-actions-zaraz/
# @see https://developers.cloudflare.com/fundamentals/api/get-started/account-owned-tokens/
resource "cloudflare_page_rule" "forward_www" {
  for_each = toset([
    "www.fergus.london/", "fergus.london/"
  ])

  zone_id = data.cloudflare_zones.blog_cf_zone.zones[0].id
  target  = each.key

  actions {
    forwarding_url {
      url         = "https://blog.fergus.london/"
      status_code = var.cloudflare_redirects_are_permanent ? 301 : 302
    }
  }

  lifecycle {
    ignore_changes = [priority]
  }
}

resource "cloudflare_page_rule" "force_https" {
  zone_id = data.cloudflare_zones.blog_cf_zone.zones[0].id
  target  = "http://*fergus.london/*"

  actions {
    always_use_https = true
  }

  lifecycle {
    ignore_changes = [priority]
  }
}
