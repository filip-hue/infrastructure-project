# outputs.tf – värden som Terraform skriver ut efter "apply".
# run.sh läser site_dir och skickar den vidare till PowerShell-skriptet.

output "site_dir" {
  description = "Absolut sökväg till den skapade miljön"
  value       = abspath(local.site_dir)
}

output "created_files" {
  description = "Lista över filer som Terraform har skapat"
  value = [
    local_file.index.filename,
    local_file.config.filename,
    local_file.logs_keep.filename,
  ]
}
