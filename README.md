# Terraform + PowerShell: skapa och verifiera en serverkatalogmiljö

## Syfte
Projektet visar en liten automatiseringskedja på Linux:
**Terraform** skapar en miljö (kataloger och konfigurationsfiler) och
**PowerShell** kontrollerar att allt blev som förväntat. Hela kedjan startas med ett kommando.

## Tekniker
- Terraform (provider `local`, resources, variabler, outputs, state)
- PowerShell (`pwsh` på Linux): parametrar, funktioner, villkor, loopar, felhantering, loggning
- Bash (`run.sh`) som startar kedjan

## Struktur
```
infrastructure-project/
├── README.md
├── run.sh                       # startar hela flödet
├── terraform/
│   ├── main.tf                  # provider och resurser
│   ├── variables.tf             # indata
│   └── outputs.tf               # utdata (site_dir)
├── powershell/
│   └── verify-environment.ps1   # verifierar resultatet
└── logs/                        # loggfil från verifieringen
```

## Så fungerar det
1. `run.sh` kör `terraform init` och `terraform apply`.
2. Terraform skapar `build/webbserver-dev/` med `html/index.html`, `config/app.json` och `logs/`.
3. `run.sh` läser Terraform-outputen `site_dir` och skickar den till PowerShell-skriptet.
4. PowerShell kontrollerar kataloger, filer och innehåll, loggar till `logs/verify.log`
   och returnerar exit-kod 0 (OK) eller 1 (fel).

## Krav
- Linux, `terraform` (>= 1.5) och `pwsh` (PowerShell 7) installerade

## Köra
```bash
chmod +x run.sh
./run.sh
```

## Testa och verifiera
- Lyckat: skriptet slutar med "RESULTAT: Alla kontroller godkända" och exit-kod 0 (`echo $?`).
- Provoka ett fel: `rm build/webbserver-dev/config/app.json` och kör
  `pwsh powershell/verify-environment.ps1 -SiteDir build/webbserver-dev` – då loggas FEL och exit-koden blir 1.
- Terraform återskapar filen vid nästa `terraform apply` (infrastruktur som kod).

## Felhantering
`set -euo pipefail` i `run.sh` avbryter om ett steg misslyckas. I PowerShell används
`try/catch`, en felräknare och exit-koder.

## Begränsningar
- Providern `local` skapar bara filer lokalt, ingen riktig server.
- PowerShell DSC och Ansible ingår inte; de är inte krav för G.
