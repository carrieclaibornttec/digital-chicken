# Point local editor skill folders at this pack.
# Directory junctions, not copies. Safe to re-run.
$ErrorActionPreference = 'Stop'
$pack = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSrc = Join-Path $pack 'skills\add-vertex-model'
if (-not (Test-Path (Join-Path $skillSrc 'SKILL.md'))) {
    throw "SKILL.md not found at $skillSrc"
}

function Link-Junction([string]$Link, [string]$Target) {
    if (Test-Path $Link) {
        $item = Get-Item $Link -Force
        $isJunction = $item.Attributes -band [IO.FileAttributes]::ReparsePoint
        if ($isJunction) {
            Write-Host "exists  $Link"
            return
        }
        throw "Refusing to replace a real folder: $Link"
    }
    $parent = Split-Path -Parent $Link
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    New-Item -ItemType Junction -Path $Link -Target $Target | Out-Null
    Write-Host "linked  $Link"
}

$user = $env:USERPROFILE
Link-Junction (Join-Path $user '.claude\skills\add-vertex-model') $skillSrc
Link-Junction (Join-Path $user '.codex\skills\add-vertex-model') $skillSrc

$glmSkills = Join-Path $user '.claude_glm_vertex\skills'
$claudeSkills = Join-Path $user '.claude\skills'
if ((Test-Path (Join-Path $user '.claude_glm_vertex')) -and -not (Test-Path $glmSkills)) {
    Link-Junction $glmSkills $claudeSkills
} elseif (Test-Path $glmSkills) {
    Write-Host "exists  $glmSkills"
}

Write-Host "Done. Start a new Claude Code or Codex session to load the skill."
