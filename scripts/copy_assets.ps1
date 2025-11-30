# Copy assets from source projects into advent/assets

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Resolve-Path "$root\.."
$destAssets = Join-Path $workspaceRoot 'assets'
if (-not (Test-Path $destAssets)) { New-Item -ItemType Directory -Path $destAssets | Out-Null }

$sources = @( '..\adfi\assets', '..\adme\assets', '..\adhi\assets' )

foreach ($rel in $sources) {
    $src = Resolve-Path (Join-Path $workspaceRoot $rel) -ErrorAction SilentlyContinue
    if (-not $src) { Write-Warning "Assets not found: $rel"; continue }
    $srcPath = $src.Path
    Write-Host "Copying assets from $srcPath"
    # copy directories css, img, js, etc.
    Get-ChildItem -Path $srcPath -Directory | ForEach-Object {
        $sub = $_.Name
        $target = Join-Path $destAssets $sub
        if (-not (Test-Path $target)) {
            Write-Host "Copying $sub to $target"
            Copy-Item -Path $_.FullName -Destination $target -Recurse -Force
        } else {
            Write-Host "Merging files in $sub (existing)"
            Get-ChildItem -Path $_.FullName -Recurse -File | ForEach-Object {
                $relPath = $_.FullName.Substring($_.FullName.IndexOf($sub))
                $destFile = Join-Path $destAssets $relPath
                $destDir = Split-Path -Parent $destFile
                if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
                if (-not (Test-Path $destFile)) {
                    Copy-Item -Path $_.FullName -Destination $destFile -Force
                    Write-Host "Copied file: $relPath"
                } else {
                    Write-Host "Skipped existing file: $relPath"
                }
            }
        }
    }
}

Write-Host "Assets copy done. Check $destAssets"
