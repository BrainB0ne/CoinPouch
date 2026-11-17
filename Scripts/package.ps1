param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$source = Split-Path -Parent $PSScriptRoot
$addonName = "CoinPouch"
$tocPath = Join-Path $source "$addonName.toc"
$releaseDirectory = Join-Path $source "Releases"

if (-not (Test-Path -LiteralPath $tocPath -PathType Leaf)) {
    throw "Missing TOC file: $tocPath"
}

$versionLine = Get-Content -LiteralPath $tocPath | Where-Object {
    $_ -match '^\s*##\s*Version\s*:'
} | Select-Object -First 1

if (-not $versionLine -or $versionLine -notmatch '^\s*##\s*Version\s*:\s*(\S+)\s*$') {
    throw "Missing or invalid '## Version:' entry in $tocPath"
}

$version = $Matches[1]
if ($version -notmatch '^[0-9A-Za-z][0-9A-Za-z._-]*$') {
    throw "Invalid version for a ZIP filename: $version"
}

$files = @(
    "$addonName.lua",
    "${addonName}Settings.lua",
    "$addonName.toc",
    "LICENSE",
    "Media\$addonName.tga"
)

foreach ($file in $files) {
    $path = Join-Path $source $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required addon file: $path"
    }
}

$zipPath = Join-Path $releaseDirectory "$addonName-v$version.zip"
if ((Test-Path -LiteralPath $zipPath) -and -not $Force) {
    throw "Release already exists: $zipPath (use -Force to overwrite)"
}

# Build in a temporary staging directory to guarantee CoinPouch/ is the ZIP root.
$staging = Join-Path ([System.IO.Path]::GetTempPath()) ("CoinPouch-package-" + [guid]::NewGuid().ToString('N'))
$stagedAddon = Join-Path $staging $addonName

try {
    New-Item -ItemType Directory -Path $stagedAddon -Force | Out-Null

    foreach ($file in $files) {
        $from = Join-Path $source $file
        $to = Join-Path $stagedAddon $file
        New-Item -ItemType Directory -Path (Split-Path -Parent $to) -Force | Out-Null
        Copy-Item -LiteralPath $from -Destination $to
        Write-Host "  Added $file"
    }

    New-Item -ItemType Directory -Path $releaseDirectory -Force | Out-Null
    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }
    Compress-Archive -LiteralPath $stagedAddon -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Host "Created: $zipPath" -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}
