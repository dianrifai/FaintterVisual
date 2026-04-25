<#
rename-assets.ps1
Use: Dry-run by default. Add -Execute to actually rename files and update HTML.
Runs in repo root; it will:
 - Find folders and files with spaces or parentheses
 - Compute safe names (replace spaces with '-', remove parentheses, remove unusual chars)
 - Rename directories (deep-first) and files
 - Update references in all .html files to the new relative paths
 - Backup changed HTML files as .bak

Example:
# Dry run (show what would change)
PowerShell -ExecutionPolicy Bypass -File .\rename-assets.ps1

# Execute changes
PowerShell -ExecutionPolicy Bypass -File .\rename-assets.ps1 -Execute
#>

param(
    [switch]$Execute
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Write-Host "Working folder:`n  $root`n" -ForegroundColor Cyan

function ToSafeName([string]$name){
    # replace spaces with dash, remove parentheses, keep letters/numbers/dash/dot/underscore
    $n = $name -replace '\s+', '-' -replace '[\(\)]','' -replace '[^A-Za-z0-9\-\._]',''
    $n = $n -replace '-{2,}','-'
    return $n
}

# Collect directories and files that need renaming (contain space or parens or uppercase issues)
$dirs = Get-ChildItem -Path $root -Recurse -Directory | Where-Object { $_.Name -match '\s|\(|\)' } | Sort-Object -Property FullName -Descending
$files = Get-ChildItem -Path $root -Recurse -File | Where-Object { $_.Name -match '\s|\(|\)' }

$map = @{}

# Prepare directory renames first (deepest first)
foreach($d in $dirs){
    $newName = ToSafeName($d.Name)
    if($newName -ne $d.Name){
        $oldFull = $d.FullName
        $newFull = Join-Path $d.Parent.FullName $newName
        $map[$oldFull] = $newFull
        if($Execute){
            Write-Host "Renaming DIR: $oldFull -> $newFull" -ForegroundColor Yellow
            Rename-Item -Path $oldFull -NewName $newName -ErrorAction Stop
        } else {
            Write-Host "DRY-RUN DIR: $oldFull -> $newFull"
        }
    }
}

# Prepare file renames
foreach($f in $files){
    $newName = ToSafeName($f.Name)
    if($newName -ne $f.Name){
        $oldFull = $f.FullName
        $newFull = Join-Path $f.DirectoryName $newName
        $map[$oldFull] = $newFull
        if($Execute){
            Write-Host "Renaming FILE: $oldFull -> $newFull" -ForegroundColor Yellow
            Rename-Item -Path $oldFull -NewName $newName -ErrorAction Stop
        } else {
            Write-Host "DRY-RUN FILE: $oldFull -> $newFull"
        }
    }
}

if($map.Count -eq 0){
    Write-Host "No files or folders need renaming based on spaces/parentheses." -ForegroundColor Green
} else {
    Write-Host "\nMappings prepared: $($map.Count) items." -ForegroundColor Cyan
}

# Helper: convert full path to relative path (posix style)
function FullToRel([string]$full){
    $rel = $full.Substring($root.Length)
    $rel = $rel -replace '^\\',''
    $rel = $rel -replace '\\','/'
    return $rel
}

# Update HTML files
$htmls = Get-ChildItem -Path $root -Recurse -Include *.html -File
foreach($hf in $htmls){
    $content = Get-Content $hf.FullName -Raw
    $updated = $content
    foreach($oldFull in $map.Keys){
        $newFull = $map[$oldFull]
        $oldRel = FullToRel($oldFull)
        $newRel = FullToRel($newFull)
        # replace both occurrences of relative paths and bare filenames
        $escapedOldRel = [Regex]::Escape($oldRel)
        $escapedOldName = [Regex]::Escape([IO.Path]::GetFileName($oldFull))
        $updated = [Regex]::Replace($updated, $escapedOldRel, $newRel)
        $updated = [Regex]::Replace($updated, $escapedOldName, [IO.Path]::GetFileName($newFull))
    }

    if($updated -ne $content){
        if($Execute){
            # backup
            Copy-Item -Path $hf.FullName -Destination ($hf.FullName + '.bak') -Force
            Set-Content -Path $hf.FullName -Value $updated -Force
            Write-Host "Updated HTML: $($hf.FullName) (backup: .bak)" -ForegroundColor Green
        } else {
            Write-Host "DRY-RUN HTML update: would update $($hf.FullName)" -ForegroundColor Magenta
        }
    }
}

Write-Host "\nDone.\n" -ForegroundColor Cyan
if(-not $Execute){
    Write-Host "This was a dry-run. Re-run with -Execute to apply changes. Example:`nPowerShell -ExecutionPolicy Bypass -File .\\rename-assets.ps1 -Execute" -ForegroundColor Yellow
} else {
    Write-Host "All renames applied. Please review, test locally, then commit & push changes to GitHub." -ForegroundColor Green
}
