#!/usr/bin/env bash
# run.sh – startar hela kedjan: Terraform -> PowerShell
# Kör från projektets rotmapp:  ./run.sh

set -euo pipefail   # avbryt vid fel, odefinierade variabler och fel i pipes

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "== Steg 1: Terraform init =="
terraform -chdir="$ROOT/terraform" init -input=false

echo "== Steg 2: Terraform apply (skapar miljön) =="
terraform -chdir="$ROOT/terraform" apply -auto-approve -input=false

# Läs output "site_dir" från Terraform (-raw ger text utan citattecken)
SITE_DIR="$(terraform -chdir="$ROOT/terraform" output -raw site_dir)"

echo "== Steg 3: PowerShell verifierar miljön =="
# Om PowerShell returnerar exit-kod 1 avbryter set -e hela skriptet
pwsh -NoProfile -File "$ROOT/powershell/verify-environment.ps1" -SiteDir "$SITE_DIR"

echo "== Klart: miljön skapad och verifierad =="
