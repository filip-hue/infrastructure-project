<#
.SYNOPSIS
    Verifierar att miljön som Terraform skapat ser ut som förväntat.

.DESCRIPTION
    Kontrollerar kataloger och filer, läser app.json och jämför innehållet med
    de värden vi förväntar oss. Resultatet loggas till fil och skärm.
    Exit-kod 0 = allt OK, 1 = minst ett fel.

.EXAMPLE
    pwsh ./powershell/verify-environment.ps1 -SiteDir ./build/webbserver-dev
#>

param(
    # Sökväg till katalogen som Terraform skapade (output "site_dir")
    [Parameter(Mandatory = $true)]
    [string]$SiteDir,

    # Förväntade värden (ska matcha Terraform-variablerna)
    [string]$ExpectedName = "webbserver",
    [string]$ExpectedEnv  = "dev",
    [int]$ExpectedPort    = 8081,

    # Loggfil
    [string]$LogFile = (Join-Path $PSScriptRoot "../logs/verify.log")
)

# Stoppa vid fel så att try/catch fungerar för cmdlets
$ErrorActionPreference = "Stop"

# Räknare för resultat
$script:Failures = 0

# Funktion: skriver till skärm och loggfil med tidsstämpel
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "{0} [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

# Funktion: kontrollerar att en sökväg finns
function Test-Exists {
    param([string]$Path, [string]$Type)   # Type = Leaf (fil) eller Container (katalog)
    if (Test-Path -Path $Path -PathType $Type) {
        Write-Log "OK   finns: $Path"
    } else {
        Write-Log "FEL  saknas: $Path" "ERROR"
        $script:Failures++
    }
}

# Se till att loggkatalogen finns innan vi loggar
New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) | Out-Null
Write-Log "Startar verifiering av $SiteDir"

try {
    # 1. Kataloger
    foreach ($dir in "html", "config", "logs") {
        Test-Exists -Path (Join-Path $SiteDir $dir) -Type Container
    }

    # 2. Filer
    $index  = Join-Path $SiteDir "html/index.html"
    $config = Join-Path $SiteDir "config/app.json"
    Test-Exists -Path $index  -Type Leaf
    Test-Exists -Path $config -Type Leaf

    # 3. Innehåll i index.html
    if (Test-Path $index) {
        if ((Get-Content $index -Raw) -match [regex]::Escape($ExpectedName)) {
            Write-Log "OK   index.html innehåller '$ExpectedName'"
        } else {
            Write-Log "FEL  index.html saknar '$ExpectedName'" "ERROR"
            $script:Failures++
        }
    }

    # 4. Innehåll i app.json (JSON -> objekt)
    if (Test-Path $config) {
        $cfg = Get-Content $config -Raw | ConvertFrom-Json
        if ($cfg.project_name -eq $ExpectedName -and
            $cfg.environment  -eq $ExpectedEnv  -and
            $cfg.port         -eq $ExpectedPort) {
            Write-Log "OK   app.json har förväntade värden"
        } else {
            Write-Log "FEL  app.json avviker: $($cfg | ConvertTo-Json -Compress)" "ERROR"
            $script:Failures++
        }
    }
}
catch {
    # Oväntat fel (t.ex. trasig JSON) – logga och räkna som misslyckande
    Write-Log "Oväntat fel: $($_.Exception.Message)" "ERROR"
    $script:Failures++
}

# Slutresultat
if ($script:Failures -eq 0) {
    Write-Log "RESULTAT: Alla kontroller godkända"
    exit 0
} else {
    Write-Log "RESULTAT: $($script:Failures) kontroll(er) misslyckades" "ERROR"
    exit 1
}
