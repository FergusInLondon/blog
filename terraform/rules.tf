import {
  to = cloudflare_page_rule.forward_www
  id = "7a847173e5a8749b39a424aded4f3172/46bdcdc98f315d710927555dfac7e05e"
}

import {
  to = cloudflare_page_rule.forward_naked
  id = "7a847173e5a8749b39a424aded4f3172/e967dbfc5ece07f36bb7b63204c6b1ce"
}

# Redirect www.fergus.london -> blog.fergus.london
resource "cloudflare_page_rule" "forward_www" {}

# Redirect fergus.london -> blog.fergus.london
resource "cloudflare_page_rule" "forward_naked" {}
