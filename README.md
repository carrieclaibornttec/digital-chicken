# Vertex skills

Shared skills for wiring new Vertex AI models into a local LiteLLM proxy and
the T3 Code, OpenCode, and Claude Desktop pickers.

## Layout

```text
vertex-skills/
  README.md
  .gitignore          machine.md is local and stays out of git
  install.ps1         junctions this pack into the local editor homes
  skills/
    add-vertex-model/
      SKILL.md        the procedure (share this)
      machine.md      this PC only (do not share, do not commit)
```

One copy of each skill lives here. Editor homes point at it. Edit the file in
this folder and every linked editor sees the change.

## Install on a new machine

1. Copy this folder somewhere stable, or clone it. Do not copy someone else's
   `machine.md`.
2. In PowerShell:

```powershell
cd <path-to>\vertex-skills
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

That creates a directory junction (not a copy):

- `%USERPROFILE%\.claude\skills\add-vertex-model` → this pack
- `%USERPROFILE%\.codex\skills\add-vertex-model` → this pack
- `%USERPROFILE%\.claude_glm_vertex\skills` → `%USERPROFILE%\.claude\skills`
  only when that home exists and has no `skills` directory yet

Junctions do not need Administrator. They break if you move this folder.
Re-run `install.ps1` after moving it.

3. Start a new Claude Code or Codex session. The skill loads at session start.

## What a peer still has to set up themselves

The skill does not install LiteLLM, ADC, or the T3 provider. Each person needs:

- their own `gcloud auth application-default login` on project `mcs-internal-codeai`
- a local LiteLLM proxy on `127.0.0.1:47862`
- their own proxy key

The first time the skill runs on their machine it should write `machine.md`
next to `SKILL.md` from the paths it discovered. That file lists local paths
and must not be committed or forwarded.

## Do not share

- `machine.md`
- `litellm-vertex\.env`
- Claude Desktop `inferenceGatewayApiKey`
- anyone's ADC or service-account JSON
