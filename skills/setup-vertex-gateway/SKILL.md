---
name: setup-vertex-gateway
description: >
  Stand up a local LiteLLM gateway so Claude Desktop and T3 Code can call Vertex
  AI models with the user's own Google account. Use when someone just installed
  T3 or Claude Desktop and wants Vertex, GLM, or the gateway connected, or when
  the local proxy on 127.0.0.1:47862 is missing. Also use for the first model on
  a machine that has no LiteLLM config yet. Do not use to add another model to a
  proxy that already runs — that is add-vertex-model. Do not use for
  Anthropic-native Claude updates, and do not route Codex through the proxy.
---

# Set up the Vertex gateway

Build the local path from the user's own Google account to Vertex, then hand
the first model to `add-vertex-model`.

Windows only. The startup path is a scheduled task and PowerShell. Stop and
say so if the machine is not Windows.

This skill installs and configures. It does not copy anyone's credentials,
proxy key, gateway key, or `machine.md`. Each person uses their own
Application Default Credentials.

Org defaults, unless the user names different ones:

- GCP project: `mcs-internal-codeai`
- Location: `global`
- Listen address: `127.0.0.1:47862`
- Suggested first model: GLM 5.2, Vertex ID `zai-org/glm-5.2-maas`,
  alias `claude-vertex-glm`, label `GLM 5.2 (Vertex)`

Do not `gcloud config set project`. Leave the user's default gcloud project
unchanged. Do not set `GOOGLE_APPLICATION_CREDENTIALS` or `vertex_credentials`.

## 0. Look before you build

Search the user profile for a LiteLLM config whose `model_list` uses
`vertex_ai/` and that listens on a loopback port.

- Found one, and something is LISTENING on its port: the gateway exists.
  Stop. Tell the user, and use `add-vertex-model` for whatever model they
  asked about.
- Found the files but nothing is listening: do not install a second copy.
  Restart that one by its port (see "Restart by port" below) and continue
  at the picker steps.
- Found nothing: continue.

Back up before the first write. Copy every file you are about to change
into `~\backups\vertex-gateway-<YYYYMMDD-HHMMSS>\`. That includes an existing
LiteLLM config, T3 `settings.json`, and any Claude Desktop profile you edit.

## 1. The user's own ADC

```bash
gcloud auth application-default print-access-token >/dev/null && echo ADC_OK
```

If that fails, stop and tell the user to run these themselves. Do not run
the browser login unprompted. Do not log in as anyone else.

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project mcs-internal-codeai
```

`login` wipes the quota project. Set it again after every login.

Confirm the token belongs to an account that can call the project. A 403
from the probe in step 3 means access is not granted. Stop and report it.
Do not guess a Model Garden click.

## 2. LiteLLM, once

Install into `~\litellm-vertex` with its own venv:

```text
python -m venv ~\litellm-vertex\venv
~\litellm-vertex\venv\Scripts\python.exe -m pip install "litellm[proxy]"
```

Generate a proxy key locally. `python -c "import secrets; print('sk-glm-' + secrets.token_hex(32))"`
is fine. Write it to `~\litellm-vertex\.env` as `LITELLM_MASTER_KEY=...` and
tighten the ACL so only the user can read it. Never print the key, never
commit the file, never put it in `machine.md` or chat.

Write `config.yaml` with an empty `model_list` and:

```yaml
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY

litellm_settings:
  drop_params: false              # surface unsupported params; do not discard them
  turn_off_message_logging: true  # keep prompts and responses out of the log
  json_logs: false
```

`drop_params: false` is required. Partner models reject Claude thinking and
tool params. Those failures must be visible.

Write `start-litellm.ps1` that:

- loads `.env` into the process environment
- removes `GOOGLE_APPLICATION_CREDENTIALS` so ADC is used
- sets `GOOGLE_CLOUD_QUOTA_PROJECT` to the project
- runs `venv\Scripts\litellm.exe --config config.yaml --host 127.0.0.1 --port 47862`
- appends stdout/stderr to `logs\litellm.log` after redacting `sk-…`,
  `Bearer …`, and `ya29.…`
- rotates the log past 10 MB

Register a scheduled task that runs that script at logon, as the user.
`LiteLLM-GLM-Vertex` is the name used on existing machines. Do not register
a second task if one already launches this script.

## 3. First model

Probe before adding a route. Never invent an ID from a display name.

```text
POST https://aiplatform.googleapis.com/v1/projects/<project>/locations/global/endpoints/openapi/chat/completions
model: zai-org/glm-5.2-maas
```

HTTP 200 with a completion continues. 404 is a wrong ID. 403 is no access.
Read the body. A 200 that carries an error payload is not success.

Append one route. Do not replace `model_list`.

```yaml
  - model_name: claude-vertex-glm
    litellm_params:
      model: vertex_ai/zai-org/glm-5.2-maas
      vertex_project: mcs-internal-codeai
      vertex_location: global
    model_info:
      display_name: GLM 5.2 (Vertex)
```

No public slug yet. T3 and Desktop get the alias only, so the picker shows
one row. When the user later adds a model, `add-vertex-model` decides the
two names.

If the user named a different first model, probe that one instead and follow
the classify rules in `add-vertex-model`. Still one alias for this pass.

## 4. Restart by port

`pkill` and killing `litellm.exe` by name leave the old process listening,
and the new one silently serves the old config.

Stop the scheduled task. Stop the PID that is LISTENING on
`127.0.0.1:47862`. Start the task again. Startup is about 25 seconds.

Then:

1. `GET /v1/models` with the key from `.env`. `claude-vertex-glm` is listed.
2. `POST /v1/chat/completions` a one-word prompt with `stream: true`.
   Require a completion, not only a models-list 200.

Do not put the key or the ADC token in the summary you write back.

## 5. Claude Desktop

Edit the LiteLLM Gateway profile, not the default Anthropic profile.
Preserve every existing Anthropic entry.

Gateway profile fields:

- `inferenceGatewayBaseUrl`: `http://127.0.0.1:47862`
- `inferenceGatewayAuthScheme`: `bearer`
- `inferenceGatewayApiKey`: the local proxy key. Write it into the profile.
  Never print it.
- `inferenceModels`: append `{ "name": "claude-vertex-glm", "labelOverride": "GLM 5.2 (Vertex)" }`

The gateway profile on existing machines is under
`%LOCALAPPDATA%\Claude-3p\configLibrary\`. Match on
`inferenceGatewayBaseUrl`, not on a filename.

If the user currently sends Claude through direct Vertex, do not convert
that profile. Create a separate gateway profile and leave the direct one.

Desktop only shows the label after the gateway profile is the one in use.
Say so. Do not flip their active profile for them.

## 6. T3 Code

Add a provider instance. Do not edit the default Claude provider.

- driver: `claudeAgent`
- display name: `GLM 5.2 Vertex`
- binary: `claude`
- `homePath`: `~/.claude_glm_vertex`
- environment:
  - `ANTHROPIC_BASE_URL` = `http://127.0.0.1:47862`
  - `ANTHROPIC_AUTH_TOKEN` = the local proxy key, sensitive, value not echoed
  - `ANTHROPIC_API_KEY` = empty string
- `customModels`: one entry, `{ "slug": "claude-vertex-glm", "name": "GLM 5.2 (Vertex)" }`

Create `~/.claude_glm_vertex` if it does not exist. Make sure
`CLAUDE_CODE_USE_VERTEX` is unset for this instance, including settings it
inherits from `~/.claude`. If it is set, requests skip the gateway and go to
Vertex as Claude, which is a different project and will fail or bill wrong.

Do not select the model. Tell the user to open a new thread and pick
`GLM 5.2 (Vertex)`.

## 7. Prove it, then write machine.md

Ask the user to run one harmless tool task on the new instance (read a file,
or create and delete a temp file). Then read the proxy log.

- The log line `completion() model= zai-org/glm-5.2-maas` (or whichever ID
  was probed) with `provider = vertex_ai` is the proof of routing.
- A model that says it is Claude is not proof. The wrapper's system prompt
  says that to every model.
- With `drop_params: false`, an unsupported thinking or tool param comes
  back as an error. Report it. Do not flip `drop_params` to true to hide it.

Write `machine.md` next to the `add-vertex-model` skill, using that skill's
"Write machine.md" section. Paths and names only. No key, no token.

Redact the log the same way the start script does before you quote it.

## Restart and rollback

Restart: stop the scheduled task, stop the LISTENING PID on the port, start
the task, wait for the port.

Rollback: stop the task and the listener, copy the backup from step 0 back
over the changed files, start the task. Removing the T3 provider instance
and the Desktop `inferenceModels` entry is part of rollback. Do not delete
the user's Anthropic profiles.

## Do not

- Do not route the Codex provider through LiteLLM, or edit its config.
- Do not change the gcloud default project.
- Do not add a second public slug to T3 during setup. One alias, one row.
- Do not enable `gemini-*-cyber-permissive` or other allowlisted SKUs.
- Do not print the proxy key, the gateway key, or an ADC token.
