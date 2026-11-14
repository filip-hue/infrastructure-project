# main.tf – Terraform skapar grundstrukturen för "servermiljön".
# Vi använder providern "local" så att allt fungerar på en vanlig Linux-dator
# utan molnkonto. Terraform skapar kataloger och filer; PowerShell verifierar sedan.

terraform {
  required_version = ">= 1.5"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# Provider-blocket är tomt eftersom "local" inte behöver någon konfiguration.
provider "local" {}

# locals = beräknade värden som vi återanvänder nedan.
locals {
  # Exempel: ../build/webbserver-dev
  site_dir = "${var.base_dir}/${var.project_name}-${var.environment}"
}

# Resurs 1: en enkel webbsida. local_file skapar även saknade föräldrakataloger.
resource "local_file" "index" {
  filename        = "${local.site_dir}/html/index.html"
  file_permission = "0644"
  content         = <<-EOT
    <!DOCTYPE html>
    <html>
      <head><title>${var.project_name}</title></head>
      <body>
        <h1>${var.project_name} (${var.environment})</h1>
        <p>Skapad med Terraform och verifierad med PowerShell.</p>
      </body>
    </html>
  EOT
}

# Resurs 2: konfigurationsfil i JSON-format. jsonencode() gör om en HCL-map till JSON.
resource "local_file" "config" {
  filename        = "${local.site_dir}/config/app.json"
  file_permission = "0644"
  content = jsonencode({
    project_name = var.project_name
    environment  = var.environment
    port         = var.port
  })
}

# Resurs 3: tom fil som gör att loggkatalogen skapas.
resource "local_file" "logs_keep" {
  filename = "${local.site_dir}/logs/.gitkeep"
  content  = ""
}
