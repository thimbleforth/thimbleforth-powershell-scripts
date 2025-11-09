<#
.SYNOPSIS
    Media backup script with hash‑based collision detection.
.DESCRIPTION
    • Walks immediate subfolders of the current directory.
    • Builds three lists:
        ◦ $list           – only media files (per $extensions)
        ◦ $allFilesList  – every file encountered
        ◦ $existingFilesList – files already present in photoBackup
    • Each entry is a hashtable: @{FullPath=$...; RelPath=$...; Hash=$...}
    • Detects name‑or‑hash collisions and lets you decide per‑file or “all”.
.NOTES
    Requires PowerShell 5.1+ (works on Windows PowerShell & PowerShell 7).
    Adjust $extensions if you need more/less file types.
#>

# ---------------------------------------
# STEP 1 – Initialise the three ArrayLists (will hold hashtables)
# ------------------------------------------------------------
$list            = New-Object System.Collections.ArrayList   # filtered media
$allFilesList    = New-Object System.Collections.ArrayList   # every file found
$collisionFiles  = New-Object System.Collections.ArrayList   # collisions detected later

# ----------------------------------------------------
# STEP 2 – Current working directory (where you invoke the script)
# -----------------------------------------------
$currentDirectory = Get-Location

# ------------------------------------------------------
# STEP 3 – Media extensions we care about (case‑insensitive)
# ------------------------------------------------------------
$extensions = @(
    '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp',
    '.heic', '.heif','.aae',              # Apple‑style images
    '.mp4', '.mov', '.avi', '.mkv', '.wmv', '.flv', '.webm',
    '.hevc', '.h265'               # High‑efficiency video
)

# ----------------------------------------------
# Helper – Compute SHA‑256 hash of a file (returns hex string)
# ------------------------------------------------------------
function Get-FileHashHex {
    param([string]$Path)
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
      $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $hashBytes = $sha256.ComputeHash($bytes)
        return ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ''
    } catch {
        Write-Warning "Could not read $Path : $_"
        return $null
    }
}

# ----------------------------------------------------
# STEP 4 – Walk each immediate sub‑folder (change to -Recurse if desired)
# ------------------------------------------------------------
Get-ChildItem -Path $currentDirectory -Directory | ForEach-Object {
    $folder = $_.FullName

    # ---- All files (populate $allFilesList) ----
    Get-ChildItem -Path $folder -File | ForEach-Object {
        $rel = $_.FullName.Substring($currentDirectory.Path.Length + 1)
        $hash = Get-FileHashHex -Path $_.FullName
        $entry = @{
            FullPath = $_.FullName
            RelPath  = $rel
            Hash     = $hash
        }
        $null = $allFilesList.Add($entry)
    }

    # ---- Media files (populate $list) ----
    Get-ChildItem -Path $folder -File |
        Where-Object { $extensions -contains $_.Extension.ToLower() } |
        ForEach-Object {
            $rel = $_.FullName.Substring($currentDirectory.Path.Length + 1)
            $hash = Get-FileHashHex -Path $_.FullName
            $entry = @{
                FullPath = $_.FullName
                RelPath  = $rel
                Hash     = $hash
            }
            $null = $list.Add($entry)
        }
}

# ------------------------------------------------------
# STEP 5 – Create destination folder (photoBackup)
# ------------------------------------------------------------
$destFolder = Join-Path $currentDirectory 'photoBackup'
if (-not (Test-Path $destFolder)) {
    New-Item -ItemType Directory -Path $destFolder | Out-Null
}

# ------------------------------------------------------------
# STEP 6 – Scan existing files in the backup folder
# ------------------------------------------------------------
$existingFilesList = New-Object System.Collections.ArrayList
Get-ChildItem -Path $destFolder -File -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring($destFolder.Length + 1)   # relative to backup root
    $hash = Get-FileHashHex -Path $_.FullName
    $entry = @{
        FullPath = $_.FullName
        RelPath  = $rel
        Hash     = $hash
    }
    $null = $existingFilesList.Add($entry)
}

# ------------------------------------------------------------
# STEP 7 – Collision detection (name or hash mismatch)
# ------------------------------------------------------------
# Build lookup tables for fast existence checks
$existingByRel = @{}
$existingByHash = @{}
foreach ($e in $existingFilesList) {
    $existingByRel[$e.RelPath] = $e
    $existingByHash[$e.Hash]   = $e
}

foreach ($new in $list) {
    $collision = $false
    $existingEntry = $null

    # 1️⃣ Same relative path?
    if ($existingByRel.ContainsKey($new.RelPath)) {
        $existingEntry = $existingByRel[$new.RelPath]
        if ($existingEntry.Hash -ne $new.Hash) {
            $collision = $true   # same name, different content
        }
    }
    # 2️⃣ Same hash but different name?
    elseif ($existingByHash.ContainsKey($new.Hash)) {
        $existingEntry = $existingByHash[$new.Hash]
        $collision = $true       # duplicate content under another name
    }

    if ($collision) {
        $collisionRecord = @{
            NewRelPath      = $new.RelPath
            NewHash         = $new.Hash
            ExistingRelPath = $existingEntry.RelPath
            ExistingHash    = $existingEntry.Hash
        }
        $null = $collisionFiles.Add($collisionRecord)
    }
}

# ------------------------------------------------------------
# STEP 8 – Show collisions (if any)
# ------------------------------------------------------------
if ($collisionFiles.Count -gt 0) {
    Write-Host "`n⚠️ Detected $($collisionFiles.Count) collision(s):`n"
    $collisionFiles |
        Format-Table @{Label='To‑be‑moved';Expression={$_.NewRelPath}},
                     @{Label='New‑Hash';Expression={$_.NewHash}},
                     @{Label='Existing';Expression={$_.ExistingRelPath}},
                     @{Label='Exist‑Hash';Expression={$_.ExistingHash}} `
        -AutoSize
} else {
    Write-Host "`n✅ No name/hash collisions – clean slate."
}

# ------------------------------------------------------------
# STEP 9 – Prompt user for each collision (or apply to all)
# -----------------------------------------------
$overwriteAll = $false
foreach ($c in $collisionFiles) {
    if ($overwriteAll) {
        # Auto‑overwrite – just copy later
        continue
    }

    Write-Host "`nCollision:"
    Write-Host "  New file      : $($c.NewRelPath)   (hash $($c.NewHash))"
    Write-Host "  Existing file : $($c.ExistingRelPath) (hash $($c.ExistingHash))"
    $answer = Read-Host "Overwrite this file? (y)es / (n)o / (a)ll"
    switch ($answer.ToLower()) {
        'y' { $c.Action = 'Overwrite' }
        'yes' { $c.Action = 'Overwrite' }
        'n' { $c.Action = 'Skip' }
       'no' { $c.Action = 'Skip' }
        'a' { $c.Action = 'Overwrite'; $overwriteAll = $true }
        'all' { $c.Action = 'Overwrite'; $overwriteAll = $true }
        default { $c.Action = 'Skip' }
    }
}

# ------------------------------------------------------------
# STEP 10 – Perform the actual copy, respecting decisions
# ------------------------------------------------------------
foreach ($new in $list) {
    $src = $new.FullPath
    $dst = Join-Path $destFolder $new.RelPath

    # Ensure target sub‑folder exists
    $targetDir = Split-Path $dst -Parent
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # Check if this file was part of a collision and what the user chose
    $collisionRec = $collisionFiles | Where-Object { $_.NewRelPath -eq $new.RelPath }
    if ($collisionRec) {
        if ($collisionRec.Action -eq 'Skip') {
            Write-Host "↩️ Skipping $($new.RelPath) (user chose not to overwrite)"
            continue
        }
        # If Action is Overwrite (or overwriteAll flag set), fall through to copy
    }

    # Normal copy (or overwrite)
    Copy-Item -Path $src -Destination $dst -Force
    Write-Host "📁 Copied $($new.RelPath) → $destFolder"
}

Write-Host "`n🎉 Backup complete. $($list.Count) media files processed."