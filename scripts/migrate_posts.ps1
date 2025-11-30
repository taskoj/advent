# Migrate posts from the three project folders into advent/_posts
# Maps:
#  - adfi -> fiona
#  - adme -> melanie
#  - adhi -> henri
#
# This script copies markdown files, and injects a `calendar: <key>`
# front-matter field if not already present.
#
# Run from PowerShell:
#   powershell -ExecutionPolicy Bypass -File .\scripts\migrate_posts.ps1

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Resolve-Path "$root\.."
$destPosts = Join-Path $workspaceRoot '_posts'
if (-not (Test-Path $destPosts)) { New-Item -ItemType Directory -Path $destPosts | Out-Null }

# Source folders relative to workspace root
$sources = @{
    'fiona' = (Join-Path $workspaceRoot '..\adfi\_posts')
    'melanie' = (Join-Path $workspaceRoot '..\adme\_posts')
    'henri' = (Join-Path $workspaceRoot '..\adhi\_posts')
}

Write-Host "Destination posts: $destPosts"

foreach ($kv in $sources.GetEnumerator()) {
    $key = $kv.Key
    $src = Resolve-Path $kv.Value -ErrorAction SilentlyContinue
    if (-not $src) {
        Write-Warning "Source folder for $key not found: $($kv.Value)"
        continue
    }
    $srcPath = $src.Path
    Write-Host "Processing source: $srcPath -> calendar: $key"
    Get-ChildItem -Path $srcPath -Filter '*.md' | ForEach-Object {
        $file = $_
        # Read raw bytes and try UTF8 first; fall back to system ANSI (Default / Windows-1252) if UTF8 appears invalid
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
        try {
            $text = [System.Text.Encoding]::UTF8.GetString($bytes)
            if ($text -match "�") {
                $text = [System.Text.Encoding]::Default.GetString($bytes)
            }
        } catch {
            $text = [System.Text.Encoding]::Default.GetString($bytes)
        }
        if ($text -match '^-{3}\s*\r?\n') {
            # we have front matter. Insert calendar: key if not present
            if ($text -match "(?m)^calendar:\s*") {
                $newText = $text
            } else {
                # Insert after the opening --- line
                $newText = $text -replace '(^-{3}\s*\r?\n)', "`$1calendar: $key`n"
            }
        } else {
            # No front matter, add it
            $newText = "---`ncalendar: $key`n---`n`n" + $text
        }
        $destFile = Join-Path $destPosts $file.Name
        # Write out UTF-8 without BOM to keep Jekyll happy
        [System.IO.File]::WriteAllText($destFile, $newText, [System.Text.Encoding]::UTF8)
        Write-Host "Copied and annotated: $($file.Name) -> $destFile"
    }
}

Write-Host "Migration done. Please inspect files in $destPosts"
