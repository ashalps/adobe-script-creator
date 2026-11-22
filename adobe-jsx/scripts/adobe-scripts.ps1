[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$List,
    [ValidateSet('Photoshop', 'Illustrator', 'AfterEffects')][string]$App,
    [string]$Source,
    [string]$Version,
    [string]$Locale,
    [switch]$Panel,
    [string[]]$AdobeRoot = @(
        (Join-Path $env:ProgramFiles 'Adobe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Adobe')
    )
)
$ErrorActionPreference = 'Stop'
$destinations = @(
    foreach ($root in $AdobeRoot) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }
        foreach ($installation in Get-ChildItem -LiteralPath $root -Directory) {
            $hostName = $null
            $hostVersion = $null
            $folders = @()
            if ($installation.Name -match '^Adobe Photoshop (.+)$') {
                $hostName = 'Photoshop'; $hostVersion = $Matches[1]
                $folders = @(Join-Path $installation.FullName 'Presets\Scripts')
            } elseif ($installation.Name -match '^Adobe Illustrator (.+)$') {
                $hostName = 'Illustrator'; $hostVersion = $Matches[1]
                $presets = Join-Path $installation.FullName 'Presets'
                if (Test-Path -LiteralPath $presets -PathType Container) {
                    $folders = @(Get-ChildItem -LiteralPath $presets -Directory | ForEach-Object {
                        Join-Path $_.FullName 'Scripts'
                    })
                }
            } elseif ($installation.Name -match '^Adobe After Effects (.+)$') {
                $hostName = 'AfterEffects'; $hostVersion = $Matches[1]
                $folders = @(Join-Path $installation.FullName 'Support Files\Scripts')
            }
            foreach ($folder in $folders) {
                if (Test-Path -LiteralPath $folder -PathType Container) {
                    $language = if ($hostName -eq 'Illustrator') { Split-Path (Split-Path $folder -Parent) -Leaf } else { '' }
                    [pscustomobject]@{ App = $hostName; Version = $hostVersion; Locale = $language; Scripts = $folder }
                }
            }
        }
    }
)
if ($List) { $destinations | Sort-Object App, Version, Locale; return }
if (-not $App -or -not $Source) { throw 'Supply -App and -Source, or use -List.' }
if ($Panel -and $App -ne 'AfterEffects') { throw '-Panel is only supported for AfterEffects.' }
$sourceFile = Get-Item -LiteralPath $Source
if ($sourceFile.PSIsContainer -or $sourceFile.Extension -ine '.jsx') { throw 'Source must be an existing .jsx file.' }
$candidates = @($destinations | Where-Object { $_.App -eq $App })
if ($Version) { $candidates = @($candidates | Where-Object { $_.Version -eq $Version }) }
elseif ($candidates.Count -gt 0) {
    $latest = ($candidates | Sort-Object @{Expression = {
        if ($_.Version -match '\d+(?:\.\d+)*') {
            $number = $Matches[0]
            if ($number -notmatch '\.') { $number += '.0' }
            [version]$number
        } else { [version]'0.0' }
    }; Descending = $true} | Select-Object -First 1).Version
    $candidates = @($candidates | Where-Object { $_.Version -eq $latest })
}
if ($Locale) { $candidates = @($candidates | Where-Object { $_.Locale -eq $Locale }) }
elseif ($candidates.Count -gt 1 -and $App -eq 'Illustrator') {
    $english = @($candidates | Where-Object { $_.Locale -eq 'en_US' })
    if ($english.Count -eq 1) { $candidates = $english }
}
if ($candidates.Count -ne 1) { throw "Found $($candidates.Count) matching destinations. Use -List and specify -Version/-Locale or -AdobeRoot to select one existing installation." }
$chosen = $candidates[0]
$folder = $chosen.Scripts
if ($Panel) { $folder = Join-Path $folder 'ScriptUI Panels' }
if (-not (Test-Path -LiteralPath $folder -PathType Container)) { throw "Script folder does not exist: $folder" }
$target = Join-Path $folder $sourceFile.Name
$sourceHash = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
if (Test-Path -LiteralPath $target) {
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $sourceHash) {
        [pscustomobject]@{ Status = 'AlreadyInstalled'; App = $App; Destination = $target; SHA256 = $sourceHash }; return
    }
}
if ($PSCmdlet.ShouldProcess($target, 'Install Adobe JSX script')) {
    if (Test-Path -LiteralPath $target) {
        $backupDir = Join-Path $sourceFile.DirectoryName '.backups'
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        $backup = Join-Path $backupDir ($sourceFile.Name + '.' + [guid]::NewGuid().ToString('N') + '.bak')
        Copy-Item -LiteralPath $target -Destination $backup
    }
    Copy-Item -LiteralPath $sourceFile.FullName -Destination $target -Force
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $sourceHash) { throw "Installed file hash mismatch: $target" }
    [pscustomobject]@{ Status = 'Installed'; App = $App; Destination = $target; SHA256 = $sourceHash }
}
