param(
    [ValidateSet("Forever", "Retail", "All")]
    [string]$Client = "Forever"
)

$ErrorActionPreference = "Stop"

$AddonName = "CoinPouch"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$LocalConfig = Join-Path $PSScriptRoot "deploy.local.ps1"

if (-not (Test-Path $LocalConfig)) {
    throw "Missing local configuration: $LocalConfig"
}

. $LocalConfig

$Clients = if ($Client -eq "All") {
    @("Forever", "Retail")
} else {
    @($Client)
}

$Files = @(
    "$AddonName.lua",
    "${AddonName}Settings.lua",
    "$AddonName.toc",
    "LICENSE",
    "Media\$AddonName.tga"
)

foreach ($TargetClient in $Clients) {
    $AddOnsPath = $AddonPaths[$TargetClient]

    if (-not $AddOnsPath -or -not (Test-Path $AddOnsPath -PathType Container)) {
        throw "Invalid AddOns path for ${TargetClient}: $AddOnsPath"
    }

    $Destination = Join-Path $AddOnsPath "CoinPouch"

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    foreach ($File in $Files) {
        $Source = Join-Path $ProjectRoot $File
        $Target = Join-Path $Destination $File

        if (-not (Test-Path $Source -PathType Leaf)) {
            throw "Missing source file: $Source"
        }

        $TargetDirectory = Split-Path -Parent $Target
        New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null

        Copy-Item -LiteralPath $Source -Destination $Target -Force
    }

    Write-Host "CoinPouch deployed to $TargetClient" -ForegroundColor Green
}