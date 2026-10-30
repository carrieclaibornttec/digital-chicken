# setup-vertex-gateway

Ask your coding agent to connect Claude Desktop and T3 Code to Vertex AI
through a local LiteLLM proxy, using your own Google account.

Run this once, on a machine that does not have the proxy yet. After that,
`add-vertex-model` is the skill for each new model.

Windows only.

## What it does

1. Checks whether a Vertex LiteLLM proxy is already on the machine. If one
   is running, it stops and points at `add-vertex-model` instead of
   installing a second copy.
2. Uses your own Application Default Credentials. If you are not signed in,
   it tells you the `gcloud` commands to run. It does not log in as someone
   else, and it does not change your default gcloud project.
3. Installs LiteLLM into `~\litellm-vertex` with its own venv, generates a
   proxy key that stays on this PC, and registers a scheduled task so the
   proxy starts at logon on `127.0.0.1:47862`.
4. Probes Vertex, then adds one route. The suggested first model is
   GLM 5.2 (`claude-vertex-glm`). Your existing Anthropic models are left
   as they are.
5. Points a Claude Desktop gateway profile and a separate T3 provider
   (`GLM 5.2 Vertex`, home `~/.claude_glm_vertex`) at the proxy.
6. Asks you to run a harmless tool task, then reads the proxy log to prove
   the call reached Vertex. Unsupported thinking or tool params are reported,
   not hidden.

Backups go in `~\backups\vertex-gateway-<timestamp>\` before the first edit.

## How to use it

Install the pack (`install.ps1` in the parent folder) and start a new
Claude Code or Codex session. Then:

```text
Set up the Vertex gateway for Claude Desktop and T3. Use my own Google account.
```

```text
I just installed T3. Connect it to Vertex, and start with GLM 5.2.
```

You still have to pick the model yourself. Open a new thread and choose
`GLM 5.2 (Vertex)`. The agent cannot click the picker.

In Claude Desktop, the label only shows while the LiteLLM Gateway profile
is selected. Your direct-Anthropic profile is left alone.

## What you need first

- Windows, PowerShell, and Python on PATH.
- `gcloud`, and a Google account that can call project `mcs-internal-codeai`.
- Claude Desktop, T3 Code, or both.

You do not need a proxy key, a `machine.md`, or anyone else's config.
The agent writes `machine.md` for `add-vertex-model` when setup succeeds.
That file is paths only. Do not commit it or send it to anyone.

## What it will not do

- Add a second name for the same model. Setup registers one alias, so the
  picker shows one row. `add-vertex-model` is what decides names later.
- Route Codex through the proxy.
- Install anything on macOS or Linux.
