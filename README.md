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

## GitHub
https://github.com/filip-hue/infrastructure-project

## Resultat
Kedjan startas med `./run.sh`. Terraform skapar miljön i `build/webbserver-dev/`,
och PowerShell verifierar den. Vid lyckad körning blir resultatet:

```
2026-11-14 12:29:35 [INFO] OK   index.html innehåller 'webbserver'
2026-11-14 12:29:35 [INFO] OK   app.json har förväntade värden
2026-11-14 12:29:35 [INFO] RESULTAT: Alla kontroller godkända
== Klart: miljön skapad och verifierad ==
```

Jag testade även att kedjan fångar fel. När jag ändrade porten i Terraform till 8081
gav PowerShell `FEL app.json avviker` och exit-kod 1, eftersom skriptet förväntade sig 8080.
Efter att jag uppdaterade det förväntade värdet blev alla kontroller godkända igen.

## Egna reflektioner
Jag använde AI som stöd för att ta fram ett första utkast av projektet. Därefter gick jag
igenom koden, körde kedjan och testade den från noll för att förstå hur den fungerar.

Det jag lärde mig är hur Terraform beskriver vad som ska skapas (provider, resources,
variabler och outputs), och hur ett värde från Terraform (`site_dir`) kan skickas vidare av
`run.sh` till ett PowerShell-skript som verifierar resultatet. Jag förstod också varför
exit-koder är viktiga: PowerShell returnerar 0 eller 1, och `run.sh` avbryter om något går fel.

Den ändring jag gjorde själv var att byta port från 8080 till 8081. Det visade att Terraform
och PowerShell måste vara överens, och att verifieringen faktiskt fångar avvikelser.
Det enda problem jag stötte på var att GitHub inte accepterar lösenord vid `git push`,
utan kräver en personlig åtkomsttoken.

Projektet är medvetet litet, eftersom jag ville ha en lösning jag kan förklara. För att
utveckla det vidare skulle jag lägga till Python för att samordna körningen och en
Ansible-playbook för att konfigurera en riktig tjänst.
