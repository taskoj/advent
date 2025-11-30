# Fix mojibake in already-migrated posts
# This assumes the files currently contain sequences like "TÃ¼rchen" where
# UTF-8 bytes were interpreted as ANSI and then saved as UTF-8. The fix:
#   - read the file as UTF-8 (PowerShell default),
#   - get the ANSI bytes for that string,
#   - decode those bytes as UTF-8 to recover the original text,
#   - write back as UTF-8.
#
# Backup option: set $MakeBackup = $true to keep original files with .bak

$MakeBackup = $true
$postsDir = Join-Path (Resolve-Path "$PSScriptRoot\..\") '_posts'
if (-not (Test-Path $postsDir)) { Write-Error "Posts folder not found: $postsDir"; exit 1 }

Get-ChildItem -Path $postsDir -Filter '*.md' | ForEach-Object {
    $file = $_.FullName
    Write-Host "Processing: $file"
    $s = Get-Content -Raw -Path $file -Encoding UTF8
    # if file doesn't seem to have mojibake, skip
    if ($s -notmatch '[ÃÂ]') { Write-Host "  No obvious mojibake, skipping."; return }

    if ($MakeBackup) { Copy-Item -Path $file -Destination "$file.bak" -Force }

    $ansiBytes = [System.Text.Encoding]::Default.GetBytes($s)
    $fixed = [System.Text.Encoding]::UTF8.GetString($ansiBytes)
    [System.IO.File]::WriteAllText($file, $fixed, [System.Text.Encoding]::UTF8)
    Write-Host "  Fixed and saved (backup: $($MakeBackup))"
}

Write-Host "Done. Inspect files in $postsDir"
