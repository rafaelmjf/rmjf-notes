# build-content.ps1 - publish pipeline: vault -> Quartz content/
# Selects notes flagged `publish: true`, follows their [[link]] + ![[embed]] closure
# (pulling linked notes and referenced images, skipping heavy .pbix binaries),
# files notes into per-collection folders, and generates a gallery index per folder.
#
# Paths are parameterized (no machine-specific hard-coding). The vault is now the
# `rmjf-vault` Git repo; point -Vault at a clone of it, or set $env:RMJF_VAULT_PATH.
# Defaults: vault = a sibling `../rmjf-vault` checkout; project = this script's folder.
#   pwsh ./build-content.ps1 -Vault /path/to/rmjf-vault
param(
  [string]$Vault = $(if ($env:RMJF_VAULT_PATH) { $env:RMJF_VAULT_PATH } else { Join-Path $PSScriptRoot ".." "rmjf-vault" }),
  [string]$Proj  = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$S = [char]0xA7   # the section sign, built here to avoid source-encoding issues

$vault     = $Vault
$proj      = $Proj
$content   = Join-Path $proj "content"
$notesDir  = Join-Path $vault "Notes"
$assetsDir = Join-Path $vault "Assets"
if (-not (Test-Path -LiteralPath $notesDir)) {
  throw "Vault Notes/ not found at '$notesDir'. Pass -Vault <path-to-rmjf-vault clone> or set RMJF_VAULT_PATH."
}
$enc = New-Object System.Text.UTF8Encoding($false)

function Get-FM($text, $key) {
  if ($text -match "(?m)^$([regex]::Escape($key)):[ \t]*(.+)$") { return $matches[1].Trim().Trim('"') }
  return ""
}
function Wikitarget($val) {
  if ($val -match '\[\[([^\]\|]+)') { return $matches[1].Trim() }
  return $val
}
# Type -> collection folder (and gallery). Unmapped types fall back to "Notes".
function FolderFor($type) {
  switch ($type) {
    "$S Skill"                { "Skills" ; break }
    "$S Dashboard Feature"    { "Dashboard Features" ; break }
    "$S Dashboard Inspiration" { "Inspirations" ; break }
    default                   { "Notes" }
  }
}

# 1) reset content
if (Test-Path $content) { Get-ChildItem $content -Recurse -Force | Remove-Item -Recurse -Force }
New-Item -ItemType Directory -Path (Join-Path $content "Assets") -Force | Out-Null

# 2) seeds = notes flagged publish: true
$seeds = @()
Get-ChildItem $notesDir -Filter *.md | ForEach-Object {
  $t = [IO.File]::ReadAllText($_.FullName)
  if ($t -match "(?m)^publish:[ \t]*true") { $seeds += $_.BaseName }
}

# 3) BFS closure over [[links]] and ![[embeds]]
$included = New-Object 'System.Collections.Generic.HashSet[string]'
$assets   = New-Object 'System.Collections.Generic.HashSet[string]'
$queue = New-Object System.Collections.Queue
$seeds | ForEach-Object { $queue.Enqueue($_) | Out-Null }
while ($queue.Count -gt 0) {
  $name = [string]$queue.Dequeue()
  if ($included.Contains($name)) { continue }
  $path = Join-Path $notesDir ($name + ".md")
  if (-not (Test-Path -LiteralPath $path)) { continue }
  [void]$included.Add($name)
  $t = [IO.File]::ReadAllText($path)
  foreach ($m in [regex]::Matches($t, '!?\[\[([^\]\|#]+)(?:[#\|][^\]]*)?\]\]')) {
    $target = $m.Groups[1].Value.Trim()
    if ($target -match '\.(png|jpe?g|gif|webp|svg)$') { [void]$assets.Add($target) }
    elseif ($target -match '\.pbix$') { }   # skip heavy binaries
    elseif (Test-Path -LiteralPath (Join-Path $notesDir ($target + ".md"))) { $queue.Enqueue($target) | Out-Null }
  }
}

# 4) read each note's text + Type once; group by Type
$notes = @{}     # name -> @{ Text; Type; Folder }
$byType = @{}
foreach ($n in $included) {
  $t = [IO.File]::ReadAllText((Join-Path $notesDir ($n + ".md")))
  $type = Wikitarget (Get-FM $t "Type")
  $folder = FolderFor $type
  $notes[$n] = [pscustomobject]@{ Text = $t; Type = $type; Folder = $folder }
  if (-not $byType.ContainsKey($type)) { $byType[$type] = @() }
  $byType[$type] += [pscustomobject]@{ Name = $n; Text = $t }
}

# 5) copy notes into their collection folder; images into shared Assets/
foreach ($n in $included) {
  $dir = Join-Path $content $notes[$n].Folder
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  Copy-Item -LiteralPath (Join-Path $notesDir ($n + ".md")) -Destination (Join-Path $dir ($n + ".md")) -Force
}
foreach ($a in $assets) {
  $src = Join-Path $assetsDir $a
  if (Test-Path -LiteralPath $src) { Copy-Item -LiteralPath $src -Destination (Join-Path (Join-Path $content "Assets") $a) -Force }
}

# 6) generate a gallery as each folder's index.md (markdown embeds/links render inside
#    HTML cards thanks to obsidian-flavored-markdown enableInHtmlEmbed: true).
#    $metaFn returns labelled field lines (joined with <br>).
function New-Gallery($folder, $type, $metaFn) {
  if (-not $byType.ContainsKey($type)) { return }
  $items = $byType[$type] | Sort-Object Name
  $L = @("---", "title: $folder", "---", "", "$($items.Count) item(s).", "", '<div class="pkm-grid">', "")
  foreach ($it in $items) {
    $img = Wikitarget (Get-FM $it.Text "Image")
    $L += '<div class="pkm-card">'; $L += ""
    if ($img) { $L += "![[$img]]"; $L += "" }
    $L += "[[$($it.Name)]]"; $L += ""
    $L += (& $metaFn $it); $L += ""
    $L += '</div>'; $L += ""
  }
  $L += '</div>'
  $dir = Join-Path $content $folder
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $dir "index.md"), ($L -join "`n"), $enc)
}

New-Gallery "Skills" "$S Skill" {
  param($it)
  ("Domain: $(Get-FM $it.Text 'Domain')", "Owner: $(Get-FM $it.Text 'Owner')", "Status: $(Get-FM $it.Text 'Status')") -join "<br>"
}
New-Gallery "Dashboard Features" "$S Dashboard Feature" {
  param($it)
  ("Technique: $(Get-FM $it.Text 'Technique')", "Designer: $(Get-FM $it.Text 'Designer')") -join "<br>"
}
New-Gallery "Inspirations" "$S Dashboard Inspiration" {
  param($it)
  ("Designer: $(Get-FM $it.Text 'Designer')", "Use case: $(Get-FM $it.Text 'Use Case')") -join "<br>"
}

# 7) home index linking the collection folders
$idx = @("---", "title: Knowledge Vault", "---", "", "A published slice of my knowledge vault.", "",
         "## Collections", "- [[Skills/index|Skills]]", "- [[Dashboard Features/index|Dashboard Features]]", "- [[Inspirations/index|Inspirations]]", "") -join "`n"
[IO.File]::WriteAllText((Join-Path $content "index.md"), $idx, $enc)

Write-Output ("Seeds flagged  : " + $seeds.Count)
Write-Output ("Notes published: " + $included.Count)
Write-Output ("Images copied  : " + $assets.Count)
Write-Output ("Folders        : " + (($notes.Values | ForEach-Object { $_.Folder } | Sort-Object -Unique) -join ", "))
