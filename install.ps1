# Point local editor skill folders at this pack.
# Directory junctions, not copies. Safe to re-run.
$ErrorActionPreference = 'Stop'
$pack = Split-Path -Parent $MyInvocation.MyCommand.Path
$skills = @('add-vertex-model', 'setup-vertex-gateway')
foreach ($name in $skills) {
    if (-not (Test-Path (Join-Path $pack "skills\$name\SKILL.md"))) {
        throw "SKILL.md not found for $name"
    }
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
foreach ($name in $skills) {
    $target = Join-Path $pack "skills\$name"
    Link-Junction (Join-Path $user ".claude\skills\$name") $target
    Link-Junction (Join-Path $user ".codex\skills\$name") $target
}

$glmSkills = Join-Path $user '.claude_glm_vertex\skills'
$claudeSkills = Join-Path $user '.claude\skills'
if ((Test-Path (Join-Path $user '.claude_glm_vertex')) -and -not (Test-Path $glmSkills)) {
    Link-Junction $glmSkills $claudeSkills
} elseif (Test-Path $glmSkills) {
    Write-Host "exists  $glmSkills"
}

Write-Host "Done. Start a new Claude Code or Codex session to load the skills."
