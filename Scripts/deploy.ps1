
$ErrorActionPreference = "Stop"

# Source: repository root
$source = Split-Path -Parent $PSScriptRoot

$configFile = Join-Path $PSScriptRoot "deploy.local.ps1"

if (-not (Test-Path -LiteralPath $configFile)) {
    throw "Missing local configuration: $configFile"
}

. $configFile

$target = Join-Path $addonsPath "CoinPouch"

$files = @(
    "CoinPouch.lua",
    "CoinPouch.toc",
    "LICENSE",
    "Media\CoinPouch.tga"
)

Write-Host "Deploying CoinPouch..." -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $addonsPath -PathType Container)) {
    throw "WoW AddOns directory not found: $addonsPath"
}

foreach ($file in $files) {
    $from = Join-Path $source $file
    $to = Join-Path $target $file

    if (-not (Test-Path -LiteralPath $from -PathType Leaf)) {
        throw "Missing source file: $from"
    }
}

foreach ($file in $files) {
    $from = Join-Path $source $file
    $to = Join-Path $target $file

    $directory = Split-Path -Parent $to
    New-Item -ItemType Directory -Path $directory -Force | Out-Null

    Copy-Item -LiteralPath $from -Destination $to -Force
    Write-Host "  Copied $file" -ForegroundColor Green
}

Write-Host "CoinPouch deployed successfully!" -ForegroundColor Green
