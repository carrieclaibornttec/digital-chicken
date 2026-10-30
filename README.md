# Vertex skills

Shared skills for a local LiteLLM gateway in front of Vertex AI, and for
adding models to it. Claude Desktop, T3 Code, and OpenCode read the gateway.

## Layout

```text
vertex-skills/
  README.md
  .gitignore          machine.md is local and stays out of git
  install.ps1         junctions this pack into the local editor homes
  skills/
    setup-vertex-gateway/
      SKILL.md        first-time proxy, Desktop, and T3 setup (share this)
      README.md
    add-vertex-model/
      SKILL.md        add one model to a gateway that already runs (share this)
      README.md
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
- `%USERPROFILE%\.claude\skills\setup-vertex-gateway` → this pack
- `%USERPROFILE%\.codex\skills\<same two>` → this pack
- `%USERPROFILE%\.claude_glm_vertex\skills` → `%USERPROFILE%\.claude\skills`
  only when that home exists and has no `skills` directory yet

Junctions do not need Administrator. They break if you move this folder.
Re-run `install.ps1` after moving it.

3. Start a new Claude Code or Codex session. The skill loads at session start.

## Which skill to run

| You have | Ask for |
|---|---|
| A fresh T3 or Claude Desktop, no local proxy | `setup-vertex-gateway` |
| A proxy already running, and a new model | `add-vertex-model` |

Setup uses your own `gcloud auth application-default login` on project
`mcs-internal-codeai`, installs LiteLLM on `127.0.0.1:47862`, and generates
your proxy key on that machine. It does not take anyone else's key.

`add-vertex-model` only adds a route. On its first run it writes `machine.md`
next to its `SKILL.md` from paths it found. Setup writes that same file when
it finishes. Either way it stays on the machine. Do not commit or forward it.

## Do not share

- `machine.md`
- `litellm-vertex\.env`
- Claude Desktop `inferenceGatewayApiKey`
- anyone's ADC or service-account JSON
