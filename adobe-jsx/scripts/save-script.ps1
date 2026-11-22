[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet('Photoshop', 'Illustrator', 'AfterEffects')][string]$App,
    [string]$Source,
    [string]$Destination,
    [string]$SettingsPath,
    [switch]$ShowSettings
)
$ErrorActionPreference = 'Stop'
if (-not $SettingsPath) {
    $codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
    $SettingsPath = Join-Path $codexRoot 'adobe-jsx\settings.json'
}
$settingsFile = [IO.Path]::GetFullPath($SettingsPath)
$folders = @{}
if (Test-Path -LiteralPath $settingsFile) {
    try {
        $settings = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json
        if ($settings.version -ne 1 -or $null -eq $settings.destinations) { throw 'Unknown settings format.' }
        foreach ($property in $settings.destinations.PSObject.Properties) {
            if ($property.Value -isnot [string] -or -not $property.Value) { throw 'Invalid saved folder.' }
            $folders[$property.Name] = $property.Value
        }
    } catch { throw "Could not read settings at '$settingsFile': $($_.Exception.Message). Keep this file for diagnosis; do not reset it silently." }
}
if ($ShowSettings) {
    [pscustomobject]@{ SettingsPath = $settingsFile; Destinations = [pscustomobject]$folders }
    return
}
if (-not $App -or -not $Source) { throw 'Supply -App and -Source, or use -ShowSettings.' }
$sourceFile = Get-Item -LiteralPath $Source
if ($sourceFile.PSIsContainer -or $sourceFile.Extension -ine '.jsx') { throw 'Source must be an existing .jsx file.' }
$remember = [bool]$Destination
if (-not $Destination) { $Destination = $folders[$App] }
if (-not $Destination) { throw "No folder is remembered for $App. Ask the user once for a save folder, then supply it with -Destination." }
if ($Destination -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\]+\\[^\\]+)') { throw 'Destination must be an absolute Windows folder path.' }
$folder = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $folder -PathType Leaf) { throw "Destination is a file, not a folder: $folder" }
$target = Join-Path $folder $sourceFile.Name
$hash = (Get-FileHash -LiteralPath $sourceFile.FullName -Algorithm SHA256).Hash
if (-not $PSCmdlet.ShouldProcess($target, 'Save JSX and remember the chosen folder')) { return }
$backup = $null
try {
    if (-not (Test-Path -LiteralPath $folder -PathType Container)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
    $same = (Test-Path -LiteralPath $target -PathType Leaf) -and ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $hash)
    if (-not $same) {
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            $backupFolder = Join-Path $folder '.backups'
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
            $backup = Join-Path $backupFolder ($sourceFile.Name + '.' + [guid]::NewGuid().ToString('N') + '.bak')
            Copy-Item -LiteralPath $target -Destination $backup
        }
        Copy-Item -LiteralPath $sourceFile.FullName -Destination $target -Force
    }
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $hash) { throw 'Saved file hash differs from source.' }
} catch { throw "Could not save JSX to '$target': $($_.Exception.Message). Finished source is still at '$($sourceFile.FullName)'." }
if ($remember) {
    $folders[$App] = $folder
    $settingsFolder = Split-Path $settingsFile -Parent
    $temporary = $null
    try {
        New-Item -ItemType Directory -Path $settingsFolder -Force | Out-Null
        $temporary = Join-Path $settingsFolder ([guid]::NewGuid().ToString('N') + '.tmp')
        $json = @{ version = 1; destinations = $folders } | ConvertTo-Json -Depth 4
        [IO.File]::WriteAllText($temporary, $json, (New-Object Text.UTF8Encoding($false)))
        Move-Item -LiteralPath $temporary -Destination $settingsFile -Force
    } catch { throw "JSX was saved and verified at '$target', but its folder could not be remembered in '$settingsFile': $($_.Exception.Message)." }
    finally { if ($temporary -and (Test-Path -LiteralPath $temporary)) { Remove-Item -LiteralPath $temporary -Force } }
}
[pscustomobject]@{
    Status = if ($same) { 'AlreadySaved' } else { 'Saved' }
    App = $App
    Path = $target
    SHA256 = $hash
    Backup = $backup
    RememberedFolder = $folder
    SettingsPath = $settingsFile
}
