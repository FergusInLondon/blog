terraform {
  cloud {
    organization = "FergusInLondon"
    workspaces {
      name = "blog"
    }
  }

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
  type = string
}

variable "cloudflare_analytics_site_token" {
  type = string
}

variable "cloudflare_redirects_are_permanent" {
  type    = bool
  default = false
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
