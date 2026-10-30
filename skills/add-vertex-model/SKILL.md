---
name: add-vertex-model
description: >
  Add a newly available Vertex AI model to this machine's local LiteLLM proxy and the
  T3 Code, OpenCode, and Claude Desktop pickers. Use whenever someone says a model just
  landed in Model Garden, Vertex, or MaaS and asks to enable, wire, add, or try it
  (Gemini, Grok, GLM, DeepSeek, Qwen, Kimi, Llama, or any other publisher). Also use
  when an existing Vertex route 404s or returns "invalid model name" after a rename.
  Do not use for Anthropic-native Claude model updates that do not go through the
  local proxy.
---

# Add a Vertex model

Wire one verified Vertex model into the local proxy and the pickers that read it.
Probe first. Never invent a model ID from a Model Garden display name.

Read `machine.md` in this directory before editing anything. It has this machine's
paths, GCP project, and account. If it is missing, write it first — see
"Write machine.md" below. Do not copy another person's proxy key, gateway key,
or ADC, and do not copy another person's `machine.md`.

Org defaults (override from `machine.md` when it disagrees):

- GCP project: `mcs-internal-codeai`
- Location: `global`
- Proxy listen address: `127.0.0.1:47862`
- Each person uses their own ADC. Never a colleague's credentials.

Auth is Application Default Credentials. Do not set `GOOGLE_APPLICATION_CREDENTIALS`
or `vertex_credentials`. Do not `gcloud config set project`. Leave the user's
default gcloud project unchanged.

## Write machine.md

`machine.md` is created on the machine, by the agent, the first time this skill
runs. It is not part of the shared pack. Peers do not receive one and should
not be handed one.

Discover, do not invent. Search the user profile for the files below. Write a
row only for a file you actually found. If the LiteLLM config or its env file
is missing, stop and say the proxy is not set up yet. Do not scaffold LiteLLM,
ADC, or the T3 provider. This skill adds a model to a proxy that already runs.

| Row | How to find it |
|---|---|
| LiteLLM config | A `config.yaml` whose `model_list` uses `vertex_ai/` and whose `general_settings` set a listen port. Record its full path. |
| Proxy key | The env file that config reads for `LITELLM_MASTER_KEY`. Record the path and the variable name only. Never the value. |
| Proxy log | The log path in the start script or config, if one is set. |
| Start script | The `.ps1` next to the config that launches LiteLLM. |
| Scheduled task | `Get-ScheduledTask` and find the task whose action runs that script. Record the task name. |
| Listen address | The host and port that script or config binds. Do not assume `127.0.0.1:47862` if the file says otherwise. |
| T3 custom models | `.t3\userdata\settings.json`. Find the `providerInstances` entry whose `ANTHROPIC_BASE_URL` is the proxy. Record the instance key and `config.customModels`. |
| OpenCode proxy models | `.config\opencode\opencode.json`. Find the provider whose `baseURL` is the proxy. Record the provider key and its `models`. |
| Desktop gateway | `AppData\Local\Claude-3p\configLibrary\*.json`, the profile whose `inferenceGatewayBaseUrl` is the proxy. Record that file and `inferenceModels`. |
| GCP project | `vertex_project` in the LiteLLM config. |
| Location | `vertex_location` in the LiteLLM config. |
| Account | `gcloud auth application-default print-access-token` succeeding is enough. Record the account from `gcloud auth list` only if it prints one. |
| Backups | A `backups` directory the user already uses. If none, use `~\backups`. |
| gcloud default project | `gcloud config get-value project`. Record it and leave it unchanged. |

Write the file next to `SKILL.md` using the same table shape as the example
below. List routes already present in the LiteLLM config at the bottom, and
say to append rather than replace.

Do not write any secret value: not `LITELLM_MASTER_KEY`, not
`inferenceGatewayApiKey`, not an ADC token, not `ANTHROPIC_AUTH_TOKEN`.

```markdown
# This machine

Local only. Do not commit this file. Do not paste the proxy key or gateway key.

| What | Path |
|---|---|
| LiteLLM config | `<full path>` |
| Proxy key | `<full path>` (`LITELLM_MASTER_KEY`) |
| Listen address | `<host:port>` |
| GCP project | `<project>` |
| Location | `<location>` |

Routes already on this proxy: `<names>`. Append. Do not drop these.
```

## 1. Probe before editing

Confirm ADC, then call Vertex directly. A one-word prompt is enough.

```bash
gcloud auth application-default print-access-token >/dev/null && echo ADC_OK
```

Candidate IDs, in this order:

- Partner / open-model MaaS: `publishers/<publisher>/models/<slug>-maas`
  Examples that already work: `zai-org/glm-5.2-maas`, `xai/grok-4.6`,
  `deepseek-ai/deepseek-v4.1-flash-maas`.
- First-party Gemini: `publishers/google/models/<id>` with no `-maas` suffix.
  Example: `gemini-4-argon`.

generateContent URL:

```text
https://aiplatform.googleapis.com/v1/projects/<project>/locations/global/publishers/<publisher>/models/<id>:generateContent
```

OpenAI-compatible chat/completions is the path LiteLLM uses for partner MaaS:

```text
https://aiplatform.googleapis.com/v1/projects/<project>/locations/global/endpoints/openapi/chat/completions
```

Body model: `"<publisher>/<id>"`.

Read the body. HTTP 200 with an error payload is not success.

| Result | Do |
|---|---|
| 200 and a completion | Continue. Record the exact publisher + model ID. |
| 404 | Wrong ID. Try the next candidate. Do not edit configs. |
| 403 / permission denied | Access is not granted. Stop and report the error. Do not guess an enable click. |
| 400 invalid model | ID shape is wrong (display name vs resource ID). Fix the ID, probe again. |
| 429 | ID exists. Back off and retry once. Do not treat 429 as "not enabled". |

On Windows, save probe JSON with a `C:/Users/...` path. Git Bash `/c/Users/...`
and `/tmp` are not the same place Python opens.

## 2. Classify

| Kind | LiteLLM `model:` | Extra params |
|---|---|---|
| First-party Gemini | `vertex_ai/<id>` | `allowed_openai_params: [reasoning_effort]`. LiteLLM maps that to `thinking_level` for Gemini 3+. Accepted levels are `LOW\|MEDIUM\|HIGH`. `MINIMAL` is HTTP 400. |
| Partner MaaS (Grok) | `vertex_ai/<publisher>/<id>` | `allowed_openai_params: [reasoning_effort]`. Grok 4.6 accepts only `minimal\|low\|medium\|high`. |
| Partner / open MaaS (GLM, DeepSeek, others) | `vertex_ai/<publisher>/<id>` | No reasoning param unless a probe proves the model accepts one. |

Do not add pinned effort routes (`-low`, `-high`) unless the user asks. The
default route is one public slug.

Two names, one upstream:

- Public slug: the real-ish name, e.g. `deepseek-v4.1-flash`.
- Claude alias: `claude-vertex-<short>`. Claude Code and Claude Desktop denylist
  competitor slugs (`grok`, `gemini`, `deepseek`). The alias is what Desktop
  registers. T3 custom models can use the public slug; keep the alias too so
  the wrapper has a name it will send.

## 3. Back up, then edit

Copy the four config files from `machine.md` into a timestamped backup directory
before the first write.

Append, never replace existing routes.

LiteLLM entry:

```yaml
  - model_name: <public-slug>
    litellm_params:
      model: vertex_ai/<publisher>/<id>   # or vertex_ai/<id> for first-party Gemini
      vertex_project: <project>
      vertex_location: global
    model_info:
      display_name: <Human Name> (Vertex)
  - model_name: claude-vertex-<short>
    litellm_params:
      model: vertex_ai/<publisher>/<id>
      vertex_project: <project>
      vertex_location: global
    model_info:
      display_name: <Human Name> (Vertex)
```

T3 `customModels` (both slugs):

```json
{ "slug": "<public-slug>", "name": "<Human Name> (Vertex)" }
```

OpenCode `vertex-proxy.models`: public slug only. Context limits are optional;
do not invent a context window. Omit `limit` if you do not know it.

Desktop `inferenceModels`: the `claude-vertex-*` alias only, with `labelOverride`
set to the human name. The gateway key stays as it is. Never print it.

## 4. Restart the proxy by port

`pkill` and killing `litellm.exe` by name leave the old process listening, and a
new process then silently serves the old config.

Stop the scheduled task named in `machine.md`. Stop the PID that is LISTENING
on `127.0.0.1:47862`, and any `litellm` PID. Start the scheduled task again.

Startup is about 25 seconds. Then:

1. `GET /v1/models` with the master key from the env file in `machine.md`. Both new names must be listed.
2. `POST /v1/chat/completions` a one-word prompt to **both** aliases.
3. Require HTTP 200 and a completion. A 200 from `/v1/models` alone is not done.

Do not put the master key, ADC token, or gateway key in chat or in the log
summary you write back.

## 5. Tell the user

- The verified Vertex ID and that both aliases returned a completion.
- Where to pick it: T3 Vertex instance, OpenCode `vertex-proxy/<slug>`
  (refresh provider status), Desktop label.
- They may need a new thread before the picker reloads.
- Self-identification is not proof. The Claude wrapper's system prompt says the
  model is Claude. The proxy log line `completion() model= ... provider = vertex_ai`
  is the proof.

## Do not

- Do not route a native Codex or Claude provider through LiteLLM. Only the
  Vertex gateway instance uses the proxy.
- Do not change `gcloud` config or replace ADC unless `print-access-token` fails.
  If it fails: `gcloud auth application-default login`, then
  `gcloud auth application-default set-quota-project <project>`.
- Do not enable `gemini-*-cyber-permissive` or other allowlisted SKUs unless the
  user is on that allowlist and a probe returns 200.
- Do not add thinking-level aliases unless asked.
