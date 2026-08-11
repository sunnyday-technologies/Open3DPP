param(
  [string]$PublishDir
)

# Build a WEB-ONLY publish directory for open3dpp.org.
#
# The site exists for one job: make the schema $id resolve. A record declares
# schema_version 0.1.0 and its schema is identified by
#   https://open3dpp.org/schemas/core/v0.1.0/open3dpp-record.schema.json
# which is exactly the repo path schemas/core/v0.1.0/…, so copying schemas/
# verbatim makes every published identifier dereference to the same bytes this
# repository holds.
#
# Allowlist, not denylist: only the files named below can reach the deploy, and
# fail-loud tripwires abort if anything unexpected, oversized or secret-looking
# lands in the output.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot  = [System.IO.Path]::GetFullPath((Join-Path $ScriptDir ".."))

if ([string]::IsNullOrWhiteSpace($PublishDir)) {
  $PublishDir = Join-Path $RepoRoot ".cloudflare\pages\open3dpp"
}
$Target = [System.IO.Path]::GetFullPath($PublishDir)
if (-not $Target.StartsWith($RepoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
  throw "Refusing to write outside project root: $Target"
}
if (Test-Path -LiteralPath $Target) { Remove-Item -LiteralPath $Target -Recurse -Force }
New-Item -ItemType Directory -Path $Target -Force | Out-Null

function Copy-PublicFile {
  param([string]$RelativePath)
  $Source = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { throw "Missing public file: $RelativePath" }
  $Dest = Join-Path $Target $RelativePath
  New-Item -ItemType Directory -Path (Split-Path -Parent $Dest) -Force | Out-Null
  Copy-Item -LiteralPath $Source -Destination $Dest -Force
}

function Copy-PublicDirectory {
  param([string]$RelativePath)
  $Source = Join-Path $RepoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $Source -PathType Container)) { throw "Missing public directory: $RelativePath" }
  $Dest = Join-Path $Target $RelativePath
  New-Item -ItemType Directory -Path $Dest -Force | Out-Null
  Copy-Item -Path (Join-Path $Source "*") -Destination $Dest -Recurse -Force
}

# --- ALLOWLIST -------------------------------------------------------------
$rootFiles = @(
  "index.html", "404.html",
  "robots.txt", "sitemap.xml", "llms.txt", "_headers",
  "README.md", "Open3DPP_SCHEMA.md", "FIELDS.md", "CHANGELOG.md",
  "CONTRIBUTING.md", "SECURITY.md", "CITATION.cff", "LICENSE", "NOTICE"
)
foreach ($f in $rootFiles) { Copy-PublicFile $f }

# schemas/ is the reason the site exists; examples/ and research/ are the
# supporting evidence a reader follows from the front page.
$publicDirs = @("schemas", "examples", "research")
foreach ($d in $publicDirs) { Copy-PublicDirectory $d }

# --- FAIL-LOUD TRIPWIRES ---------------------------------------------------
$publishFiles = Get-ChildItem -LiteralPath $Target -Recurse -File

# 1. No machinery or VCS metadata in the output.
$blocked = @("scripts", ".github", ".git", ".cloudflare", "node_modules")
foreach ($b in $blocked) {
  $hit = Join-Path $Target $b
  if (Test-Path -LiteralPath $hit) { throw "Blocked path reached the publish dir: $b" }
}

# 2. Nothing oversized — this site serves text, not binaries.
$tooBig = $publishFiles | Where-Object { $_.Length -gt 2MB }
if ($tooBig) { throw "Oversized file(s) in publish dir: $($tooBig.FullName -join ', ')" }

# 3. No secret-looking strings.
$secretPatterns = @(
  'CLOUDFLARE_API_TOKEN\s*[:=]\s*\S',
  'ghp_[A-Za-z0-9]{20,}',
  'AKIA[0-9A-Z]{16}',
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
)
foreach ($f in $publishFiles) {
  if ($f.Extension -in @('.md', '.json', '.txt', '.html', '.cff', '.toml', '.fdm_material', '.csv')) {
    $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction SilentlyContinue
    foreach ($p in $secretPatterns) {
      if ($content -match $p) { throw "Secret-looking string in $($f.FullName) (pattern $p)" }
    }
  }
}

# 4. The whole point: every published schema must be present and parseable.
$schemaFiles = Get-ChildItem -LiteralPath (Join-Path $Target "schemas") -Recurse -Filter *.json
if (-not $schemaFiles) { throw "No schema files reached the publish dir" }
foreach ($s in $schemaFiles) {
  $json = Get-Content -LiteralPath $s.FullName -Raw | ConvertFrom-Json
  if (-not $json.'$id') { throw "Schema without an \$id: $($s.FullName)" }
  # The served path must match the identifier, or the $id still will not resolve.
  $rel = $s.FullName.Substring($Target.Length).Replace('\', '/').TrimStart('/')
  $expected = "https://open3dpp.org/$rel"
  if ($json.'$id' -ne $expected) {
    throw "Schema \$id does not match its served path: $($json.'$id') != $expected"
  }
}

Write-Host "Publish dir built: $Target ($($publishFiles.Count) files, $($schemaFiles.Count) schemas)"
