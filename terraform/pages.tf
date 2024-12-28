resource "cloudflare_pages_project" "blog_pages_project" {
  account_id        = var.cloudflare_account_id
  name              = "blog"
  production_branch = "master"

  source {
    type = "github"
    config {
      owner                         = "FergusInLondon"
      repo_name                     = "blog"
      production_branch             = "master"
      pr_comments_enabled           = true
      deployments_enabled           = true
      production_deployment_enabled = true
      preview_deployment_setting    = "all"
      preview_branch_includes       = ["*"]
      preview_branch_excludes       = ["master"]
    }
  }

  build_config {
    build_command   = "hugo --gc --minify"
    destination_dir = "public"
    root_dir        = ""
  }

  deployment_configs {
    preview {
      environment_variables = {
        HUGO_VERSION = local.HUGO_VERSION
        NODE_VERSION = local.NODE_VERSION
      }
      fail_open = true
    }
    production {
      environment_variables = {
        HUGO_VERSION = local.HUGO_VERSION
        NODE_VERSION = local.NODE_VERSION
      }
      fail_open = true
    }
  }
}

resource "cloudflare_pages_domain" "cloudflare_blog_domain" {
  account_id   = var.cloudflare_account_id
  project_name = cloudflare_pages_project.blog_pages_project.name
  domain       = "blog.fergus.london"
}
