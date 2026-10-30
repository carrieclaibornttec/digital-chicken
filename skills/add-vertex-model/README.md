# add-vertex-model

Ask your coding agent to wire a new Vertex AI model into the local LiteLLM
proxy and the T3 Code, OpenCode, and Claude Desktop pickers.

The agent follows `SKILL.md`. You do not edit the proxy config yourself.

## What it does

When a model shows up in Model Garden, Vertex, or MaaS, the skill:

1. Calls Vertex with your own Application Default Credentials and confirms the
   real model ID. A Model Garden display name is not an API ID.
2. Adds two names that point at that one model:
   - the public slug, for T3 and OpenCode (`deepseek-v4.1-flash`)
   - a `claude-vertex-*` alias, because Claude Code and Claude Desktop refuse
     competitor names like `grok`, `gemini`, and `deepseek`
3. Appends those names to the LiteLLM config, T3 custom models, OpenCode
   `vertex-proxy`, and the Claude Desktop gateway. Existing routes stay.
4. Restarts the proxy by the process listening on `127.0.0.1:47862`, then
   requires a real chat completion from both names. A models list alone is
   not enough.

It stops without editing configs if Vertex returns 404 (wrong ID) or 403
(access not granted). It does not click anything in Model Garden for you.

## How to use it

Install the pack first (`install.ps1` in the parent folder), then start a
new Claude Code or Codex session so the skill loads.

Then say what landed, in the editor that has the skill:

```text
Gemini 4 Argon just showed up in our Vertex Model Garden. Add it.
```

```text
Can we add DeepSeek V4.1 Flash through Vertex?
```

```text
grok-4.6 is 404ing. The route name may have changed — fix it.
```

Name the model the way you saw it. The agent probes candidate IDs and does
not guess a resource ID from the label.

You need a new thread before T3 or Desktop shows the new name. In OpenCode,
refresh provider status and pick `vertex-proxy/<slug>`.

## What "done" looks like

The agent should tell you:

- the Vertex ID that actually returned a completion
- that both the public slug and the `claude-vertex-*` alias returned one
- where to pick it (T3 Vertex instance, OpenCode, Desktop label)

Do not trust the model if it says it is Claude. The Claude wrapper's system
prompt tells every model that. The proof is the LiteLLM log line
`completion() model= ... provider = vertex_ai`.

## What it will not do

- Route native Claude or Codex through the proxy. Only the Vertex gateway
  instance uses LiteLLM.
- Change your gcloud default project, or use someone else's credentials.
- Add separate low/medium/high routes unless you ask.
- Enable allowlisted SKUs such as `gemini-*-cyber-permissive` unless a probe
  already returns 200 for your account.

## First run on a new machine

If `machine.md` is missing, the agent looks up the four config files
(LiteLLM, T3, OpenCode, Desktop gateway) and writes `machine.md` beside
`SKILL.md`. That file is this PC only. Do not commit it or send it to
anyone. It must not contain the proxy key or the Desktop gateway key.

You still need, before the first run:

- `gcloud auth application-default login` on project `mcs-internal-codeai`
- a local LiteLLM proxy on `127.0.0.1:47862`
- your own proxy key

See the pack `README.md` for install and for the list of files not to share.
