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
$tempZipPath = Join-Path $releaseDirectory (".$addonName-v$version-" + [guid]::NewGuid().ToString('N') + ".zip")

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
    # Build the new archive separately so a compression failure cannot erase
    # an existing release. The temporary ZIP is on the same volume as the target.
    Compress-Archive -LiteralPath $stagedAddon -DestinationPath $tempZipPath -CompressionLevel Optimal

    if (-not (Test-Path -LiteralPath $tempZipPath -PathType Leaf) -or
        (Get-Item -LiteralPath $tempZipPath).Length -eq 0) {
        throw "Packaging failed: temporary ZIP is missing or empty: $tempZipPath"
    }

    # Atomically replace an existing ZIP, retaining the old one if replacement
    # fails. On first release, simply move the completed ZIP into place.
    if (Test-Path -LiteralPath $zipPath) {
        if (-not $Force) {
            throw "Release already exists: $zipPath (use -Force to overwrite)"
        }
        [System.IO.File]::Replace($tempZipPath, $zipPath, [NullString]::Value)
    }
    else {
        Move-Item -LiteralPath $tempZipPath -Destination $zipPath
    }
    Write-Host "Created: $zipPath" -ForegroundColor Green
}
finally {
    if (Test-Path -LiteralPath $tempZipPath) {
        Remove-Item -LiteralPath $tempZipPath -Force
    }
    if (Test-Path -LiteralPath $staging) {
        Remove-Item -LiteralPath $staging -Recurse -Force
    }
}
