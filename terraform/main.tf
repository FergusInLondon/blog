terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

locals {
  HUGO_VERSION = "0.126.0"
  NODE_VERSION = "22.11.0"
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

variable "cloudflare_account_id" {
  type = string
}

variable "cloudflare_analytics_site_tag" {
  type    = string
  default = "860fdc0261c14a20b2cbc622cfe5c730"
}

variable "cloudflare_analytics_site_token" {
  type    = string
  default = "2c9efb4bb9ba4e6abbbccd744bf5852f"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
