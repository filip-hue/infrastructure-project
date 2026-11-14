# variables.tf – indata till Terraform. Värdena kan ändras utan att main.tf rörs.

variable "project_name" {
  description = "Namn på miljön, används i katalognamn och på webbsidan"
  type        = string
  default     = "webbserver"
}

variable "environment" {
  description = "Miljö, t.ex. dev eller test"
  type        = string
  default     = "dev"
}

variable "base_dir" {
  description = "Katalog där miljön skapas (relativt terraform-mappen)"
  type        = string
  default     = "../build"
}

variable "port" {
  description = "Portnummer som skrivs in i app.json"
  type        = number
  default     = 8080
}
