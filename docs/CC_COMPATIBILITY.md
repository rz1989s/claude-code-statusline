# Claude Code Version Compatibility Notes

Per-version compatibility log for Claude Code releases from v2.1.77 through v2.1.169. The statusline uses **feature detection** (field existence), not version comparison, so it gracefully handles missing or unknown fields via the `get_json_field()` abstraction.

For the current JSON schema baseline (path migration, worktree, rate_limits, effort/thinking, etc.) and the manual test command, see [CLAUDE.md](../CLAUDE.md). Schema-additive versions are summarized there; this file is the per-version archive.

---

## v2.1.77–v2.1.79, v2.1.81

No new statusline-relevant fields. v2.1.81 added `--bare` flag and MCP collapsible output. Zero JSON schema changes.

## v2.1.82

Skipped (no public release).

## v2.1.83–v2.1.85

No new statusline-relevant JSON fields.

## v2.1.86

Fixed model field bleed across concurrent sessions (CC-side fix). Zero JSON schema changes.

## v2.1.87–v2.1.92

No new statusline-relevant JSON fields.

## v2.1.93, v2.1.95

Skipped (no public release).

## v2.1.94

Changed default effort to `high` for API-key/Bedrock users. No JSON changes.

## v2.1.96

Bedrock auth hotfix. No JSON changes.

## v2.1.97 — Schema-additive

`workspace.git_worktree` (string, set when cwd is inside a linked git worktree via `git worktree add` — distinct from the top-level `worktree` object for `claude --worktree` sessions). Also introduces `refreshInterval` statusline setting (CC re-runs statusline every N seconds).

## v2.1.98

Perforce mode env var, improved vim `j`/`k` history nav, 429 retry backoff fix. Zero additional JSON schema changes beyond v2.1.97.

## v2.1.99

Skipped (never published to npm).

## v2.1.100

Silent release with no public changelog entry — only an internal CC system-prompt tweak for agent behavior. Zero JSON changes.

## v2.1.101

`/team-onboarding` command, OS CA cert trust (`CLAUDE_CODE_CERT_STORE`), `/ultraplan` auto-env, brief/focus mode polish, subagent MCP inheritance, permissions precedence fix, Bedrock SigV4 Authorization fix, and numerous UX fixes (`/resume` picker, Grep ripgrep self-heal, memory leak fixes, hardcoded 5-min timeout fix, `/btw` disk bloat, `/context` accounting, `/mcp` OAuth menu, `ctrl+]`/`\`/`^` keybindings). Zero JSON schema changes.

## v2.1.102

npm-published carrier for v2.1.101's features (same CC-internal fixes). Zero JSON changes.

## v2.1.103, v2.1.104, v2.1.106

Skipped (not released on npm).

## v2.1.105

`EnterWorktree` path param, PreCompact hook blocking, plugin `monitors` manifest key, stalled-stream abort-after-5min, `/doctor` layout, rendering fixes. Zero JSON changes.

## v2.1.107

Earlier thinking hints during long operations. Zero JSON changes.

## v2.1.108

`ENABLE_PROMPT_CACHING_1H` env var, `/recap` feature, Skill-tool invocation of built-in slash commands, `/undo` alias, memory-footprint reduction. Zero JSON changes.

## v2.1.109

Extended-thinking progress hint. Zero JSON changes.

## v2.1.110

`/tui` command + `tui` setting (fullscreen mode), push-notification tool, `Ctrl+O` verbose-toggle rebind, `/focus` command, MCP SSE hang fix, auto-scroll config. Zero JSON schema changes.

## v2.1.111 — Opus 4.7 release

Released Claude Opus 4.7 (`claude-opus-4-7`, same pricing as Opus 4.6: $5/$25), `xhigh` effort level, auto mode for Max subscribers, `/less-permission-prompts` skill, `/ultrareview`, "Auto (match terminal)" theme, Windows PowerShell tool, `Ctrl+U`/`Ctrl+L` changes, fixes `/clear` dropping `session_name` set by `/rename`. Zero JSON schema additions — pricing pattern `claude-opus-4-7-*` added in v2.24.1.

## v2.1.112

Hotfix for "claude-opus-4-7 temporarily unavailable" in auto mode, reverts v2.1.110's non-streaming-fallback cap. Adds iTerm2+tmux display tearing fix, `@` file-suggestion rescan fix, LSP-diagnostic ordering fix, `/resume` tab-completion picker fix, `/context` grid rendering fix. Zero JSON changes.

## v2.1.113

Replaces the bundled JS entrypoint with a native per-platform binary (spawned via optional dependency) — stdin piping semantics unchanged, statusline invocation unaffected. Also: `sandbox.network.deniedDomains`, `/loop` Esc-to-cancel, `/ultrareview` parallelization, 10-min subagent stall limit, `Bash(rm:*)` hardening on `/private/{etc,var,tmp,home}`, deny-rule matching for `env`/`sudo`/`watch`/`ionice`/`setsid` wrappers, tighter `Bash(find:*)` auto-approval (excludes `-exec`/`-delete`), Opus-4.7-via-Bedrock Application Inference Profile ARN fix, MCP concurrent-call watchdog fix, resumed-long-context compaction fix. Zero JSON schema changes.

## v2.1.114

Single hotfix for a permission-dialog crash when an agent-teams teammate requests tool permission. Zero JSON changes.

## v2.1.115

Skipped (never published to npm).

## v2.1.116

Polish/reliability release: `/resume` up to 67% faster on large sessions, faster MCP startup (stdio + deferred `resources/templates/list`), smoother fullscreen scrolling in VS Code/Cursor/Windsurf, thinking spinner inline progress, `/config` value search, `/doctor` openable mid-response, sandbox auto-allow respects dangerous-path check for `rm`/`rmdir` on `/`/`$HOME`, release-download host moved from `storage.googleapis.com` to `downloads.claude.ai`, many rendering/scrollback/Kitty-protocol fixes. Zero JSON changes.

## v2.1.117

`CLAUDE_CODE_FORK_SUBAGENT=1`, `--agent` main-thread sessions load agent frontmatter `mcpServers`, `/model` pin persists across restarts with startup badge, `/resume` offers to summarize stale sessions, concurrent local+claude.ai MCP connect is now default. Native macOS/Linux builds now embed `bfs` (Glob) and `ugrep` (Grep) routed through Bash. **Default effort bumped to `high` for Pro/Max on Opus 4.6 and Sonnet 4.6** (was `medium`).

**Notable fix**: Opus 4.7 sessions were computing `/context` against a 200K window instead of its native 1M — purely a CC-internal display fix. The native `context_window_size: 1000000` in the JSON was always correct, so statuslines reading that field (ours does, via `get_native_context_window_size()`) were already accurate. Zero JSON changes.

## v2.1.118 — Vim VISUAL mode expansion

**Vim visual mode (`v`) and visual-line mode (`V`)** with operators — the existing JSON `vim.mode` field can now take `VISUAL`/`VISUAL_LINE` values alongside `NORMAL`/`INSERT` (value-set expansion, not a schema change; the `vim_mode` component renders them opaquely).

Also: `/cost` and `/stats` merged into `/usage` (both remain as shortcuts), custom named themes via `/theme` or `~/.claude/themes/*.json`, hooks can invoke MCP tools directly via `type: "mcp_tool"` (hook config schema, not statusline input), new `DISABLE_UPDATES` env, `claude plugin tag` for release tags, `--continue`/`--resume` now match sessions that added cwd via `/add-dir`, credential save no longer corrupts `~/.claude/.credentials.json` on Linux/Windows, `/fork` writes pointer-on-disk instead of full parent conversation. Zero JSON schema changes.

## v2.1.119 (23 Apr 2026) — Schema-additive

`effort.level` (string — indicates agent's effort setting, e.g. `"high"`/`"xhigh"`) and `thinking.enabled` (bool — whether extended thinking is on). Both are additive — the statusline's `get_json_field()` reads only fields it cares about, so unknown fields are ignored gracefully (verified).

Also: `/config` persists to `~/.claude/settings.json` with precedence, `prUrlTemplate` setting for custom PR badge URLs, `CLAUDE_CODE_HIDE_CWD` env, `--from-pr` accepts GitLab/Bitbucket/GHE URLs, `--print` honors agent `tools:`/`disallowedTools:` frontmatter, `--agent` honors `permissionMode`, PowerShell auto-approval, `PostToolUse`/`PostToolUseFailure` hooks get `duration_ms`, OTel adds `tool_use_id`/`tool_input_size_bytes`, parallel MCP server reconnect, `owner/repo#N` uses git remote host, vim Esc behavior tweak, numerous fixes (`/usage` bar overlap, `/export` model display, CRLF paste, Glob/Grep on Bash-denied, `${ENV_VAR}` in MCP headers).

## v2.1.120 (24 Apr 2026)

Windows PowerShell-as-shell, `claude ultrareview` CLI subcommand, `${CLAUDE_EFFORT}` skill var, fd-exhaustion fix in `find`. Zero JSON schema changes.

## v2.1.121 (27 Apr 2026)

`alwaysLoad` MCP config option, `claude plugin prune`, `PostToolUse` `updatedToolOutput` for all tools, fullscreen scroll fixes, `mcp_authenticate` `redirectUri`, OTel adds `stop_reason`/`gen_ai.response.finish_reasons`/`user_system_prompt`, large memory-leak fixes (`/usage` ~2GB, image processing). Zero JSON schema changes.

## v2.1.122 (28 Apr 2026)

`ANTHROPIC_BEDROCK_SERVICE_TIER` env var, `/resume` accepts PR URLs from all forges, `/mcp` connector dedup hints, OTel emits numeric attrs as numbers + `claude_code.at_mention` event, `/branch` fork fix, Bedrock ARN effort fix, image resize cap (2000px). Zero JSON schema changes.

## v2.1.123 (29 Apr 2026)

Single-bullet hotfix for an OAuth 401 retry loop when `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1` is set. Zero JSON schema changes.

## v2.1.124 (30 Apr 2026)

Ctrl+R history picker switched to project-scoped default (later reverted in v2.1.129). Zero JSON schema changes.

## v2.1.125

Skipped (never published to npm).

## v2.1.126 (1 May 2026)

`/v1/models` gateway discovery (auto, opt-in in v2.1.129); `claude project purge` command; `--dangerously-skip-permissions` bypasses .claude/.git/.vscode write prompts; OAuth code-paste fallback (WSL2/SSH); `claude_code.skill_activated` OTel event with `invocation_trigger`; Windows PowerShell 7 detection (Store/MSI/.NET); `allowManagedDomainsOnly` security fix; image >2000px auto-downscale; many UX/IDE/Stream-idle/wake fixes. Zero JSON schema changes.

## v2.1.127

Skipped (never published to npm).

## v2.1.128 (4 May 2026)

`/model` picker collapses Opus 4.7 entries; `--plugin-dir` accepts `.zip`; `--channels` works with API key auth; subprocesses no longer inherit `OTEL_*`; MCP `workspace` reserved server name; `EnterWorktree` creates from local HEAD (was `origin/<default>`); 1M-context autocompact false-block fix; vim NORMAL `Space` cursor-right; parallel shell tool sibling cancel fix; Bedrock default model region prefix fix; sub-agent prompt cache fix (~3× cache reduction); headless `init.plugin_errors` includes `--plugin-dir` failures. Zero JSON schema changes.

## v2.1.129 (5 May 2026)

`--plugin-url <url>`; `CLAUDE_CODE_FORCE_SYNC_OUTPUT=1`; `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE`; plugin manifest `themes`/`monitors` move under `"experimental"` (top-level still works with warning); `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` opt-in (reverts v2.1.126–v2.1.128 auto behavior); Ctrl+R defaults back to all-projects (reverts v2.1.124); `skillOverrides: off|user-invocable-only|name-only` works; `claude_code.pull_request.count` OTel counts MCP-created PRs/MRs; 1h prompt cache TTL fix; cache-miss-after-/clear fix; `Bash(mkdir *)`/`Bash(touch *)` allow-rule fix; `deniedMcpServers` `*://` mixed-case fix; `/context` no longer dumps ASCII grid (~1.6k tokens saved/call); OAuth refresh-after-wake race fix. Zero JSON schema changes.

## v2.1.130

Skipped (never published to npm).

## v2.1.131 (6 May 2026)

Hotfix-only — VS Code extension Windows activation fix (createRequire polyfill), Mantle endpoint `x-api-key` header fix. Zero JSON schema changes.

## v2.1.132 (6 May 2026) — Notable correctness improvement

`CLAUDE_CODE_SESSION_ID` env var to Bash subprocess env; `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1`; "Pasting…" footer hint; SIGINT graceful shutdown fix; `--resume` emoji-truncation surrogate fix; `--permission-mode` plan-mode fix; fullscreen-blank-after-sleep fix; vim NFD-accent corruption fix; paste-starting-with-`/` fix; mouse-wheel speed fix in Cursor/VSCode 1.92–1.104; JetBrains 2025.2 scroll fix; `/effort` picker honors `CLAUDE_CODE_EFFORT_LEVEL`; `/status` default-model fix; Alt+T thinking toggle on macOS without "Option as Meta"; stdio MCP non-protocol stdout 10GB+ RSS fix; MCP `tools/list` silent-fail retry+badge ("connected · tools fetch failed"); claude.ai MCP "needs auth" vs "failed" distinction; Bedrock/Vertex 400 with `ENABLE_PROMPT_CACHING_1H` fix.

**Notable CC-side fix that improves statusline correctness**: `context_window.*` token counts no longer reflect cumulative session totals — they now correctly reflect current context usage. Schema unchanged; CC was previously sending wrong values. After this fix, our `context_window.current_usage.*` and `context_window.used_percentage` display accurate current-context values automatically (passive improvement, no code changes required). Zero JSON schema changes.

## Pricing update (v2.24.1, statusline-side)

`claude-opus-4-7-*` glob added to `lib/cost/pricing.sh` (same tier as Opus 4.6) — prevents bare-ID fallback to Sonnet default.

## v2.1.133 (7 May 2026)

`worktree.baseRef` setting (`fresh`|`head`); `sandbox.bwrapPath`/`sandbox.socatPath` (Linux/WSL); `parentSettingsBehavior` admin key for SDK; `effort.level` now exposed to hooks via `$CLAUDE_EFFORT` env (the JSON field itself was added in v2.1.119, so this is hook-side plumbing only); focus mode polish; fixes for parallel-session 401 race, `Edit`/`Write` allow rules on drive roots/POSIX paths, MCP OAuth proxy/mTLS, `--add-dir` mapped network drives, Remote Control cancel, `/effort` concurrent-session bug, subagent skill discovery; VSCode `claudeProcessWrapper` "Unsupported platform" fix. Zero JSON schema changes.

## v2.1.134, v2.1.135

Skipped (never published to npm).

## v2.1.136 (8 May 2026)

Major polish/bugfix release (~45 fixes). New: `CLAUDE_CODE_ENABLE_FEEDBACK_SURVEY_FOR_OTEL` env, `settings.autoMode.hard_deny`. Notable fixes: MCP servers from `.mcp.json`/plugins/connectors disappearing after `/clear`; concurrent OAuth credential write race; MCP OAuth refresh-token loss with multiple servers; redacted-thinking-after-tool 400 error; `--resume`/`--continue` with underscores in path; plan mode honoring `Edit(...)` allow rules; WSL2 image paste via PowerShell fallback; `/usage` weekly reset showing date instead of time; numerous rendering fixes (CJK, ReasonML diffs, fullscreen, scrollback). Zero JSON schema changes.

## v2.1.137 (9 May 2026)

Single-bullet hotfix — VSCode extension failing to activate on Windows. Zero JSON schema changes.

## v2.1.138 (9 May 2026)

Changelog states only "Internal fixes" — no public-facing details. Sparse release notes confirmed against official changelog. Zero JSON schema changes.

## v2.1.139 (10 May 2026)

Agent view (Research Preview) — single list of every Claude Code session; `/goal` command (set a completion condition and Claude keeps working across turns); `/scroll-speed` command with live preview; `claude plugin details <name>` shows component inventory + projected per-session token cost; transcript view nav (`?`/`{`/`}`/`v`); hook `args: string[]` exec form (spawns command directly without shell); hook `continueOnBlock` for `PostToolUse`; MCP stdio servers receive `CLAUDE_PROJECT_DIR` in env; compaction prompt preserves sensitive instructions; `/mcp` Reconnect picks up `.mcp.json` edits without restart; `/context all` per-skill token estimates account for tokenizer; `claude plugin install <name>@<marketplace>` auto-refreshes; API requests from subagents carry `x-claude-code-agent-id`/`x-claude-code-parent-agent-id` headers; Remote Control/`/schedule`/claude.ai MCP connectors/notification prefs disabled when `ANTHROPIC_API_KEY`/`apiKeyHelper`/`ANTHROPIC_AUTH_TOKEN` set; many fixes (`autoAllowBashIfSandboxed`+shell expansions, hook-corrupting-prompt, HTTP/SSE non-protocol memory growth, `Skill(name *)` wildcard prefix, settings hot-reload on symlinks, plugin details marketplace-key mismatch, `/model` picker `ANTHROPIC_DEFAULT_*_MODEL` overrides, stream-idle-timeout-after-response, MCP cache dir unwritable, transcript click+letter shortcuts, Bash-mode up-arrow history, multi-image paste, hyperlink dark navy on dark, model picker redundant "Current model" row, mouse wheel scroll in Cursor/VSCode 1.92-1.104, Windows Terminal/VSCode scroll, MCP `@server:` autocomplete stale, two-file diff truncation count, Grep Windows drive paths, CJK/emoji border overflow, fuzzy-match emoji split, ProgressBar fractional-cell rendering, fs.watch resurrection, plugin manifest-name mismatch, Insights Time-of-Day chart skew, cmd/super/win-only keybindings, `active_time.total` OTel in `--print` mode, `plugin update` cross-plugin symlinks). Zero JSON schema changes.

## v2.1.140 (11 May 2026)

Agent tool `subagent_type` matching now case- and separator-insensitive; updated agent color palette; fixes for `/goal` silent hang under `disableAllHooks`/`allowManagedHooksOnly`, settings hot-reload symlinked-files misattribution, `claude --bg` connection-dropped-mid-request on idle-exit, background service startup on enterprise endpoint security, remote managed settings not retrying on 401, managed `extraKnownMarketplaces` auto-update policy not persisted, `/loop` redundant wakeups while polling background tasks, recurring Windows event-loop stall on missing-executable spawns, `Read` `offset` validation with whitespace/`+` prefix, native terminal cursor on focus loss, plugin default-folder warnings. Zero JSON schema changes.

## v2.1.141 (13 May 2026) — Statusline render fix

~45-bullet release. New: hook `terminalSequence` field (enables desktop notifications/window-titles/bells without a controlling terminal), `CLAUDE_CODE_PLUGIN_PREFER_HTTPS` env (clone GitHub plugin sources over HTTPS instead of SSH), `ANTHROPIC_WORKSPACE_ID` env (workload identity federation scoping), `claude agents --cwd <path>`, `/feedback` multi-session bundles (last 24h/7d), Rewind menu "Summarize up to here", auto-mode permission dialog explains `permissions.ask` cause, restored "view diff in your IDE" on file-edit prompts when IDE connected, `/bg` and `←←` background-launches preserve permission mode, `claude agents` moves completed-but-shell-running sessions to Completed, color-changing thinking spinner after 10s, improved plugin menu nav.

**Notable for statusline correctness**: *"Fixed multi-line statusline output dropping or corrupting rows when lines exceed terminal width"* — purely a CC-side render fix; CC was mis-handling our 7–9 line output when terminal columns ≤ line width. After this fix, wrapped/narrow terminals display all rows without corruption (passive improvement, no code changes required on our end).

Also fixes: `claude daemon status`/`/doctor` on Windows; `claude agents` interface launch through wrappers; `claude agents` crashed-session redundant dispatches; background jobs auto-naming on custom `ANTHROPIC_BASE_URL`; `/model` autocompact-threshold cross-session bleed; permission-mode switch during open tool-permission prompt; Enter submitting both prompt+input box; hooks receiving non-existent `transcript_path` after `EnterWorktree` cwd switch; markdown table wrapping fallback; cancelled-prompt history loss (Ctrl+C/Esc); Ctrl+C in vim INSERT/VISUAL; `chat:submit` keybinding when `enter` rebound to `chat:newline`; prompt suggestions silently disabled by output style; `spinnerVerbs` in turn-completion; AskUserQuestion popup hiding chat content; Web Search status incorrect search count; light-ansi theme invisible white diff context; error overlay minified bundle dump; feedback-survey-digit Enter submission; `x` keystroke in agent panel; session title from monitor notifications before first prompt; "Allowed by PermissionRequest hook" repeats; `/tui` dropping background shells/subagents; welcome banner "API Usage Billing" on third-party providers; `/mcp` server list focus visibility in fullscreen; `/feedback` redaction producing invalid JSON; desktop/third-party providers inheriting `apiKeyHelper`/`ANTHROPIC_AUTH_TOKEN`; early analytics events dropped; `claude plugin install` stale upstream `ref`; plugin details 0-MCP-servers for `.mcp.json` declarations; MCP unset config-variable generic failure; POSIX shell-parameter-expansion flagging; MCP HTTP/SSE 403 shown as "failed" instead of "needs auth"; remote MCP optional events-stream disconnect; Remote Control 401 on token rotation; Remote Control re-enroll on stale token; OTel early-span drop; `voice:pushToTalk`/`"space": null` unbinds silently ignored; Windows Alt+V image paste; SDK "native binary not found" on glibc+musl Linux; Bedrock `awsCredentialExport` always runs; VSCode mic-silence feedback; VSCode voice WSL sox hint; `claude agents` pre-warmed worker unhealthy; `claude agents` empty placeholder cleanup; empty-idle background sessions auto-retired after 5 min. Zero JSON schema changes.

## v2.1.142 (14 May 2026)

~24-bullet release. New: `claude agents --add-dir`/`--settings`/`--mcp-config`/`--plugin-dir`/`--permission-mode`/`--model`/`--effort`/`--dangerously-skip-permissions` flags for dispatched background sessions; `MCP_TOOL_TIMEOUT` env now properly raises per-request fetch timeout for remote HTTP/SSE MCP servers (was hardcoded 60s cap); **Fast mode now defaults to Opus 4.7** (was Opus 4.6) — opt-out via `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1` (already covered by our `claude-opus-4-7-*` pricing pattern, zero changes needed). Fixes: background sessions now recognize pre-existing git worktrees (`EnterWorktree` no longer refuses duplicate, `worktree.*` field semantics unchanged); `brew upgrade` daemon zombies; macOS clock-jump detection on sleep-wake; Apple Terminal 256-color bleed on color-changing spinner. Zero JSON schema changes.

## v2.1.143 (15 May 2026)

~20-bullet release published to npm. New: plugin dependency enforcement (`claude plugin disable` refuses when another enabled plugin depends on target; `claude plugin enable` force-enables transitive deps); projected per-turn + per-invocation context cost shown in `/plugin` marketplace browse pane; `worktree.bgIsolation: "none"` setting (bg sessions edit working copy directly without `EnterWorktree`); PowerShell tool now passes `-ExecutionPolicy Bypass` by default (opt-out: `CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY=1`); PowerShell tool **enabled by default on Windows** for Bedrock/Vertex/Foundry (opt-out: `CLAUDE_CODE_USE_POWERSHELL_TOOL=0`); background sessions preserve model + effort level after waking from idle; Shift+Tab in attached agent sessions now includes auto mode in the cycle; `claude agents` accepts `--add-dir`/`--settings`/`--mcp-config`/`--plugin-dir`/`--permission-mode`/`--model`/`--effort`/`--dangerously-skip-permissions` (matches v2.1.142 flags for dispatched bg sessions); `claude --bg --dangerously-skip-permissions` persists across retire→wake; `/bg` preserves `--mcp-config`/`--settings`/`--add-dir`/`--plugin-dir`/`--strict-mcp-config`/`--fallback-model`/`--allow-dangerously-skip-permissions`; bg sessions launched from `claude agents` honor `permissions.defaultMode` from settings.json; worktree cleanup no longer falls back to `rm -rf` when `git worktree remove` fails; Stop hooks blocking repeatedly now end turn with warning after 8 blocks (override: `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`).

Fixes: corrupt `.credentials.json` non-array `scopes` hanging CLI; right-click paste in `claude agents` Windows Terminal/WSL; Esc/Ctrl+C not cancelling pending `/loop` wakeup; `/goal` evaluator firing while bg shells/subagents still running; `NO_COLOR`/`FORCE_COLOR` in settings.json `env` stripping CC's own UI colors; agent view spawning repeated PowerShell processes on Windows; `/bg` without prompt sending "continue"; `--agent <name>` not finding plugin-contributed agents without `plugin:` prefix; deleting session from agent view leaving transcript file; stale-fragment rendering scrolling attached bg sessions on Windows Terminal; bg agents false-positive worker-stall storm after sleep/App Nap; 5xx error msgs pointing at status.claude.com instead of configured gateway/cloud provider; bg sessions silently capturing IDE file references into warm spare's input; macOS bg sessions "Operation not permitted" reading `~/Documents`/`~/Desktop`/`~/Downloads` even with Full Disk Access; Windows ← in `claude agents` during streaming leaving list unresponsive; bg daemon spawn falling back to running binary when `~/.local/bin/claude` launcher missing; `claude agents --allow-dangerously-skip-permissions` defaulting to bypass mode.

**Statusline fully compatible through v2.1.143 via feature detection** — verified via render simulation (clean output, `CC:2.1.143` and `SL:2.24.11` both visible) and full test suite (1070/1072 pass, 2 pre-existing skips). No code changes; docs/version bump only. Manual test command now uses `version: "2.1.143"`.

## v2.1.144 (18 May 2026) — Schema-additive

**Two new objects added to the statusline stdin JSON**: `workspace.repo` (`host`, `owner`, `name` — repository identity parsed from the git `origin` remote) and top-level `pr` (`number`, `url`, `review_state`). Changelog: *"Status line JSON input now includes GitHub repo and PR information when detected."* `workspace.repo` is absent outside a git repo or with no `origin` remote; `pr` is absent until an open PR for the current branch is found and is removed once it merges/closes. `review_state` is one of `approved`/`pending`/`changes_requested`/`draft`. Both objects are additive, conditional, and backward-compatible — `get_json_field()` ignores unknown fields and the statusline references neither, so nothing breaks. Documented in [CLAUDE.md](../CLAUDE.md); no statusline component consumes them yet (a future `pr`-aware component is an opportunity, not a requirement). Also: `/extra-usage` renamed `/usage-credits` (old name still works), `/resume` for background sessions, `/model` scopes to the current session, Bedrock/Vertex "Opus (1M context)" `/model`-picker regression fix.

## v2.1.145 (19 May 2026)

Reconfirms the v2.1.144 statusline schema entry (`workspace.repo` + `pr`) — same delta. Stop/SubagentStop **hook** input gained `background_tasks` and `session_crons` fields; that is hook-input schema, not statusLine stdin, so zero statusline impact. Also: `claude agents --json`, `/plugin` shows components pre-install, a permission-prompt bypass fix, `/review` deprecated-GraphQL fix, Read tool returns a truncated "PARTIAL view" instead of a hard error on oversized reads. Zero statusLine stdin changes beyond the v2.1.144 fields.

## v2.1.146 (20 May 2026)

Published to npm but has **no public changelog entry** — the official changelog and GitHub `CHANGELOG.md` skip from v2.1.145 to v2.1.147. Published, not skipped (distinct from genuinely unreleased versions). Zero documented changes; zero JSON schema changes.

## v2.1.147 (21 May 2026)

`/simplify` renamed to `/code-review` (effort-leveled correctness review; `--comment` posts inline PR comments) — a slash-command rename, not a JSON schema change. Also: pinned background sessions stay alive when idle, improved auto-updater, enterprise login-restriction enforcement fix. Introduced a regression — the Bash tool returning exit code 127 on every command for some users — fixed in v2.1.148. Zero JSON schema changes.

## v2.1.148 (22 May 2026)

Single-bullet release: *"Fixed the Bash tool returning exit code 127 on every command for some users"* — a pure bug fix for the v2.1.147 regression. No JSON schema changes, no new fields, no new model IDs, no statusLine setting changes.

## v2.1.149 (22 May 2026)

Polish + bugfix release. New: enterprise managed setting `allowAllClaudeAiMcps` (loads claude.ai cloud MCP connectors alongside `managed-mcp.json` — does not affect statusline `mcp.servers` schema), `/usage` per-category breakdown (skills/subagents/plugins/per-MCP-server cost — purely in-CC view, no JSON exposure), GFM task-list checkbox rendering in markdown. Status bar bugfix: now reflects skill/agent `effort:` frontmatter instead of baseline `/effort` setting — this is CC's built-in status display, not custom statuslines. Also: 4 security fixes and ~15 bug fixes. Zero JSON schema changes.

## v2.1.150 (23 May 2026) — Current

Silent internal release with no user-facing changes (changelog does not enumerate v2.1.150 separately from v2.1.149's polish; published to npm as the latest dist-tag). Zero JSON schema changes, zero new model IDs, zero new statusLine settings.

**Statusline fully compatible through v2.1.150 via feature detection** — verified via render simulation (clean 8-line output, `CC:2.1.150` and `SL:2.24.15` both visible, exit 0; the v2.1.144 `workspace.repo`/`pr` fields continue to be ignored gracefully). Both v2.1.149 and v2.1.150 are fully passive from a statusline standpoint — no code changes needed, the feature-detection architecture absorbs them automatically. Full test suite is green in CI on the shipping commit; a local sandbox run continues to show the same ~42 environmental failures inherited from the v2.1.148 update (mock-command test harness, network-dependent prayer tests, MCP tests skewed by running bats inside a Claude Code session, pre-existing `migrate_legacy_cache` BW01) — none related to v2.1.149 or v2.1.150. Docs/version bump only (v2.24.14 → v2.24.15); manual test command now uses `version: "2.1.150"`.

## v2.1.151

Skipped (never published to npm; absent from the npm versions list, which jumps v2.1.150 → v2.1.152).

## v2.1.152 (27 May 2026)

Polish/feature release. New: `MessageDisplay` hook event, `SessionStart` hook `reloadSkills`/`sessionTitle` outputs, skill `disallowed-tools` frontmatter, `/reload-skills`, `/code-review --fix`, vim reverse-search, OTel `app.entrypoint`. **Notable correctness (transcript-side, not stdin schema)**: fixed `cache_creation_input_tokens` reporting as 0 in transcript/result usage when the API reports cache writes only via the nested `cache_creation` breakdown. The statusline reads `cache_creation_input_tokens` from the transcript JSONL for historical cost, so this is a passive accuracy improvement — no code changes required. Zero stdin JSON schema changes, zero new model IDs.

## v2.1.153 (28 May 2026) — Statusline-relevant (env vars)

**Status line commands now receive `COLUMNS` and `LINES` environment variables** so scripts can size output to the terminal width. This is the long-awaited delivery for the responsive-width system: prior CC versions did not forward `$COLUMNS` to the piped statusline subprocess (the v2.23.0 width-detection saga documented in the project memory), forcing a conservative fallback to 120. As of v2.1.153, `lib/responsive.sh`'s existing detection chain (`ENV_CONFIG_TERMINAL_WIDTH` → `$COLUMNS` → fallback 120) picks up the real terminal width automatically on CC ≥ 2.1.153 — no logic change needed, only comment/doc accuracy updates (done in v2.25.0). `$LINES` is newly available too (not consumed yet; the responsive system filters by width, not height). This is env-var delivery to the subprocess, not a JSON schema change. Also: `modelPicker:setAsDefault` → `modelPicker:thisSessionOnly` keybinding rename (irrelevant to statusline). Zero stdin JSON schema changes.

## v2.1.154 (28 May 2026) — Opus 4.8 release

**Released Claude Opus 4.8** (`claude-opus-4-8`) — base pricing identical to Opus 4.6/4.7 ($5 input / $25 output / $6.25 5m-cache-write / $10 1h-cache-write / $0.50 cache-read per MTok, verified against the official pricing table). Defaults to `high` effort; `/effort xhigh` for the hardest tasks (the `xhigh` level itself shipped with Opus 4.7 in v2.1.111). **Pricing pattern `claude-opus-4-8` / `claude-opus-4-8-*` added to `lib/cost/pricing.sh` (case + awk block) in v2.25.0** to prevent the bare-ID→Sonnet-default fallback (same fix as Opus 4.6 in v2.24.0 and Opus 4.7 in v2.24.1). Empirically confirmed real transcripts emit the clean bare id `claude-opus-4-8` — CC's internal 1M-selector string `claude-opus-4-8[1m]` does not reach the JSONL/stdin `model.id`, so the bare + dated-glob patterns fully cover cost tracking. **Fast mode for Opus 4.8 is now 2× the standard rate for 2.5× speed** (down from the 6× premium on Opus 4.6/4.7); fast mode is not modeled in the statusline cost calc, so no change there. `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` deprecated (removal 06/01) — not referenced by the statusline. `worktree.baseRef: "head"` spawn fix is internal (no stdin field change). Also introduced dynamic workflows and a lean default system prompt (CC-internal, no statusline impact). Zero new stdin JSON fields, zero removed fields.

## v2.1.155

Skipped (absent from the npm versions list, which jumps v2.1.154 → v2.1.156).

## v2.1.156 (28 May 2026) — Opus 4.8 thinking-block fix

npm `latest` dist-tag and the installed CC release at the time of the v2.25.0 update, when **its public changelog had not yet been published** (the GitHub side lagged the npm/binary distribution channel). It has since surfaced as a single-line fix — *"Fixed an issue when using Opus 4.8 where thinking blocks were modified, leading to API errors."* No schema deltas beyond v2.1.154. **Verified compatible via live render against the actual installed v2.1.156 binary**: clean multi-line output, `CC:2.1.156` shown (the statusline detects the real `claude --version` via its `external_claude_version_shared.cache`), Opus 4.8 priced at $5/$25, and the `workspace.repo`/`pr`/`rate_limits`/`effort`/`thinking` fields all handled, exit 0. The feature-detection architecture absorbs any undocumented additive fields gracefully; when Anthropic publishes the v2.1.155/v2.1.156 notes, any genuinely new fields can be folded in then.

**Statusline fully compatible through v2.1.156** — Opus 4.8 cost support added (pricing pattern + 3 new pricing tests, 46/46 pass), the COLUMNS/LINES responsive-width delivery documented, render verified against the live 2.1.156 binary. Full suite is the CI gate (Ubuntu); the local sandbox shows the same ~42 environmental failures inherited from prior updates (mock-command harness, network prayer tests, in-session MCP skew, `migrate_legacy_cache` BW01) — none related to v2.1.152–156. v2.25.0 is a **minor** bump (new model pricing support, not docs-only). Manual test command now uses `version: "2.1.156"` with `claude-opus-4-8`.

## v2.1.157 (29 May 2026) — plugins + worktrees + bugfix

npm `latest` dist-tag and the installed CC binary (`claude --version` → 2.1.157). A large **plugins + worktrees + bugfix** release, not a schema release. The headline changes are developer-workflow oriented and CC-internal: plugins in `.claude/skills` auto-load without a marketplace, a new `claude plugin init <name>` scaffolder, `/plugin` argument autocomplete, the `agent` field in `settings.json` now honored for dispatched `claude agents` sessions (with `--agent` override), `EnterWorktree` can switch between Claude-managed worktrees mid-session, and Claude-managed worktrees are left unlocked on finish. The remainder is ~25 bug fixes (image-paste/corrupt-image handling, sandbox permission prompts, `claude agents` session retirement, `--resume`/`--worktree` fixes, scrollback/redraw glitches, WSL image paste, VS Code/Cursor/Windsurf terminal paste + GPU-acceleration). Two **UI-only** removals (the "bash commands will be sandboxed" startup banner and the "/ide for …" startup hint) touch no JSON. One telemetry addition — `tool_parameters` on the `tool_decision` OTel event, gated behind `OTEL_LOG_TOOL_DETAILS=1` — is OTel output, **not** statusline stdin JSON. The lone "status" wording ("Feature of the Week credit-claim status now appears as a notification in the status area") refers to CC's own internal notification UI, not custom statuslines.

**Zero stdin JSON schema changes, zero new model IDs, zero pricing changes, zero new statusline env vars.** The `COLUMNS`/`LINES` env-var delivery and Opus 4.8 pricing landed earlier (v2.1.153 and v2.1.154 respectively) and are already handled. **Statusline fully compatible through v2.1.157 via feature detection** — verified by render simulation against v2.1.157 JSON (clean multi-line output, `CC:2.1.157` shown, Opus 4.8 priced $5/$25, `workspace.repo`/`pr`/`rate_limits`/`effort`/`thinking` all handled, exit 0). `SL:2.25.1` is confirmed at the post-install verify — `get_statusline_version()` reads the installed `~/.claude/statusline/version.txt` first and the repo `version.txt` only as a developer fallback, so the dev render shows the still-installed SL version until install. Docs/version bump only (v2.25.0 → **v2.25.1**, patch); the full suite is the CI gate (Ubuntu). Manual test command now uses `version: "2.1.157"`.

**Note on v2.1.155**: skipped (never published to npm — the registry jumps 2.1.154 → 2.1.156). Cross-source agreement (npm `latest`=2.1.157 + GitHub `CHANGELOG.md` + code.claude.com docs + installed binary) confirmed v2.1.157 as the newest release at the time of the v2.25.1 update, with no statusline-facing schema impact.

## v2.1.158 (30 May 2026) — Auto mode on Bedrock/Vertex/Foundry (docs-only)

npm `latest` AND `next` dist-tag (`{ stable: 2.1.149, latest: 2.1.158, next: 2.1.158 }`); installed CC binary = 2.1.158 (`claude --version`). The code.claude.com docs changelog still caps at v2.1.157 — docs lag the npm/binary channel, the documented pattern — but the **raw GitHub `CHANGELOG.md` has the v2.1.158 entry verbatim**, so cross-source agreement holds (npm registry + raw `CHANGELOG.md` + `claude --version`).

**The entire v2.1.158 changelog is a single bullet**: *"Auto mode is now available on Bedrock, Vertex, and Foundry for Opus 4.7 and Opus 4.8. Opt in by setting `CLAUDE_CODE_ENABLE_AUTO_MODE=1`."* This is a backend cloud-provider routing feature — Auto mode (automatic effort/model selection) extended from first-party to Bedrock/Vertex/Foundry for the two already-shipped Opus 4.x models, behind an opt-in env var. **It does not add, change, or remove any field in the statusline stdin JSON**, introduces no new model ID (Opus 4.7 and 4.8 already exist and are already priced at $5/$25 in `lib/cost/pricing.sh`), and no statusline component consumes auto-mode state. A WebSearch initially mis-attributed v2.1.157's MCP/OAuth/credential bug-fix bullets to v2.1.158; the raw `CHANGELOG.md` is definitive that v2.1.158 has exactly one bullet — cross-checked and corrected.

**Zero new JSON fields, zero changed/removed fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.2 → **v2.25.3**, docs-only; the intervening v2.25.2 was the unrelated transcript cost de-duplication fix, so the prior compat baseline was v2.25.1/v2.1.157). **Statusline fully compatible through v2.1.158 via feature detection** — verified by render simulation against v2.1.158 JSON AND against the live installed 2.1.158 binary (clean 9-line output, `CC:2.1.158` shown, `Claude Opus 4.8` @ $5/$25, all `workspace.repo`/`pr`/`rate_limits`/`vim:VISUAL`/`effort`/`thinking` fields handled, exit 0; `SL:` shows the installed version until Step 13 reinstall, per the `lib/core.sh:77` lookup order). Local full suite (60 unit+integration files; `test_date_filtering.bats` excluded — known to hang inside a CC session): **1050 ok / 41 not-ok**, all 41 the known-environmental set (`create_mock_command` can't write `mock_bin/` → curl/ping mocks fail, cascading through prayer/GPS/location/connectivity; in-session MCP skew; `migrate_legacy_cache` BW01; cache-integration temp-dir sensitivity) — none related to v2.1.158, which changes zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.158"`.

## v2.1.159 (31 May 2026) — no-op maintenance (docs-only)

npm `latest` AND `next` dist-tag (`{ stable: 2.1.150, latest: 2.1.159, next: 2.1.159 }`); installed CC binary = 2.1.159 (`claude --version`). **For once the docs are in sync** — the code.claude.com changelog (the old `docs.claude.com/en/docs/claude-code/changelog` URL now 301-redirects there), the raw GitHub `CHANGELOG.md`, and the GitHub release body all carry the identical single line, and the npm registry agrees. `npm view @anthropic-ai/claude-code@2.1.160` returns E404, confirming v2.1.159 is the newest published release.

**The entire v2.1.159 changelog / GitHub release body is one line**: *"Internal infrastructure improvements (no user-facing changes)."* No features, no schema changes, no model changes, no documented bug fixes, no `statusLine`-command or env-var changes. From a statusline-consumer standpoint it is fully transparent — nothing to adapt to. Claude Opus 4.8 (`claude-opus-4-8`, $5/$25, shipped v2.1.154) remains the newest model and is already priced in `lib/cost/pricing.sh`.

**Research correctness note**: an initial WebFetch summary of the docs changelog mis-attributed `effort.level` (a stdin field) and the `COLUMNS`/`LINES` env vars to v2.1.157. The raw v2.1.157 `CHANGELOG.md` entry contains neither — that release is purely plugins/worktrees/bugfixes. `effort.level` actually landed in v2.1.119 and `COLUMNS`/`LINES` in v2.1.153 (both already documented above). Treat the misattribution as debunked, not a real change — a recurring reminder to cross-check the raw CHANGELOG over search-engine/summarizer output.

**Zero new/changed/removed JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.3 → **v2.25.4**, docs-only). **Statusline fully compatible through v2.1.159 via feature detection** — verified by render simulation against v2.1.159 JSON in two shapes (Opus 4.6 + `rate_limits`, and the full Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` blob): clean 9-line output both times, `CC:2.1.159` shown, `Claude Opus 4.8` priced $5/$25, all conditional fields handled, exit 0 (`SL:2.25.3` until the Step 13 reinstall stamps 2.25.4, per the `lib/core.sh` lookup order). Local full suite (`npm test`): **1074 ok / 42 not-ok** (1116 of an expected 1118 executed; **real npm exit = 1**), all 42 the known-environmental set — `migrate_legacy_cache` BW01 (1), the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/connectivity (34), cache-integration XDG/git temp-dir sensitivity (4), in-session MCP/resilience skew (3) — none related to v2.1.159, which changes zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.159"`.

## v2.1.160 (1 Jun 2026) — `next`-channel canary, no changelog (docs-only)

Published to the npm **`next`** channel only — `npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.150, latest: 2.1.159, next: 2.1.160 }`. This is the **first compat update whose target is not on the `latest` tag**: by the project's own "latest real version = npm `latest`" rule, `latest` is still v2.1.159, and v2.1.160 is a pre-promotion canary the local binary auto-updated to (`claude --version` → 2.1.160, published 2026-06-01 20:03 UTC). RECTOR opted to ship the full pipeline anyway — the statusline is verifiably compatible with the installed binary and the daily release cadence makes promotion imminent.

**No changelog exists anywhere.** The code.claude.com changelog, the raw GitHub `CHANGELOG.md`, and the GitHub releases page all cap at v2.1.159; `gh api .../releases/tags/v2.1.160` → 404; third-party trackers (claudeupdates.dev, marckrenn) 404 the 2.1.160 page; the npm tarball is a thin 17 KB wrapper carrying no bundled changelog. So unlike every prior entry, there is **no release text to quote** — the assessment is from binary inspection + render, not documentation.

**No detectable schema or model change.** A `strings` scan of the installed 2.1.160 binary surfaces the full existing field set (`rate_limits`, `five_hour`/`seven_day`, `workspace.repo`, `review_state`, `context_window`, `refreshInterval`, `exceeds_200k_tokens`, `worktree`, `git_worktree`) and **no new field names**; no new model-ID strings (Opus 4.8 `claude-opus-4-8` @ $5/$25 remains newest, already priced in `lib/cost/pricing.sh`). The immediately-prior v2.1.159 was itself a no-op maintenance release, so 2.1.160 most plausibly continues internal-only work.

**Zero new/changed/removed JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.4 → **v2.25.5**, docs-only). **Statusline fully compatible through v2.1.160 via feature detection** — verified by render simulation against the **live installed 2.1.160 binary** (full Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits` blob): clean 9-line output, `CC:2.1.160` shown, `Claude Opus 4.8` priced $5/$25, 1M context %, all conditional fields handled, exit 0 (`SL:2.25.4` until the Step 13 reinstall stamps 2.25.5, per the `lib/core.sh` lookup order). Local full suite (`npm test`): **1074 ok / 42 not-ok** (1116 of an expected 1118 executed; **real npm exit = 1**, masked as 0 in the background task-notification per the documented pipe/`echo $?` gotcha — the true exit is in the `TEST_EXIT=` log line), all 42 the known-environmental set — `migrate_legacy_cache` BW01, the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/connectivity, cache-integration temp-dir sensitivity, in-session MCP skew — none related to v2.1.160, which changes zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.160"`.

## v2.1.161 (2 Jun 2026) — developer-workflow + bugfix (docs-only)

npm `latest` AND `next` dist-tag — `npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.152, latest: 2.1.162, next: 2.1.162 }` (v2.1.161 held `latest`/`next` on its 2026-06-02 publish, superseded by v2.1.162 the next day). **Fully documented** — the code.claude.com changelog, the raw GitHub `CHANGELOG.md`, and the GitHub release body all carry the v2.1.161 entry, corroborated by third-party trackers (claudeupdates.dev: "22 changes", 2026-06-02). A **developer-workflow + bugfix** release: headline items are OTEL metric labels, a refreshed `claude agents` TUI, parallel-tool-call isolation, Linux clipboard support, MCP secret redaction, and improved terminal-rendering performance. The render-perf/layout-engine work is CC's *own* renderer — it does not touch how statusline output is measured (`measure_visible_width`) or displayed. None of these add, change, or remove a statusline stdin JSON field, introduce a model, or change pricing. Opus 4.8 (`claude-opus-4-8`, $5/$25, v2.1.154) remains the newest model, already priced in `lib/cost/pricing.sh`. **Zero new/changed/removed JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars.** Folded into the same v2.25.6 docs-only PATCH bump as v2.1.162 (the prior documented release was v2.1.160, so this run covers both 161 and 162).

## v2.1.162 (3 Jun 2026) — CLI/UX + MCP/LSP bugfix (docs-only, target)

npm `latest` AND `next` dist-tag — `{ stable: 2.1.152, latest: 2.1.162, next: 2.1.162 }`; installed CC binary = 2.1.162 (`claude --version`). **The promoted public `latest` release** — unlike v2.1.160 (which shipped `next`-only while `latest` stayed at 2.1.159), v2.1.162 sits on `latest`, with cross-source agreement across the npm registry + raw GitHub `CHANGELOG.md` + code.claude.com docs + GitHub release body + installed binary. A **CLI/UX + MCP/LSP bugfix** release: the headline bullet is that `claude agents --json` now includes a `waitingFor` field (what a blocked/waiting agent session is waiting on, e.g. a permission prompt), plus a `--tools` Grep/Glob fix, `/effort` persistence confirmation, autocomplete/footer UX polish, and MCP timeout/permission/LSP fixes. **Critical distinction**: `waitingFor` is emitted by the `claude agents --json` *CLI subcommand* output, **not** the JSON piped to statusline commands on stdin — no statusline consumes `claude agents --json`, so it is **not** a statusline-stdin schema change and is non-actionable. The `claude agents` "full terminal width" fixes are for the agents TUI, not statusline width. **Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.5 → **v2.25.6**, docs-only; the single bump covers both v2.1.161 and v2.1.162). **Statusline fully compatible through v2.1.162 via feature detection** — verified by render simulation against the full Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits` blob with `"version":"2.1.162"`: clean 9-line output, `CC:2.1.162` shown, `Claude Opus 4.8` priced $5/$25, 1M context %, all conditional fields handled, exit 0 (`SL:2.25.5` pre-install, until the Step 13 reinstall stamps 2.25.6, per the `lib/core.sh` lookup order). Local full suite (`npm test`): **1075 ok / 41 not-ok** (1116 of an expected 1118 executed; **real npm exit = 1**, masked as 0 in the background task-notification per the documented pipe/`echo $?` gotcha — true exit read from the `TEST_EXIT=` log line), all the known-environmental set — `migrate_legacy_cache` BW01, the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/connectivity, cache-integration temp-dir sensitivity, in-session MCP skew — none related to v2.1.161/162, which change zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.162"`.

**Retroactive note on v2.1.160**: the previously-undocumented `next`-channel canary (assessed from binary `strings` + render in the prior compat run) has since gained a real changelog entry — shell-startup-file write prompts, `acceptEdits` build-config prompts, a vim `p` paste fix, and the `ultracode` keyword rename. A security/UX release, still **no schema or model change**, consistent with the prior "no detectable schema change" finding.

## v2.1.163 (4 Jun 2026) — managed-settings + plugins + hooks + bugfix (docs-only, target)

npm `latest` AND `next` dist-tag — `npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.163, next: 2.1.163 }`; installed CC binary = 2.1.163 (`claude --version`). **The promoted public `latest` release** (not a `next`-only canary like v2.1.160 was), with cross-source agreement across the npm registry + raw GitHub `CHANGELOG.md` + code.claude.com docs changelog + GitHub release body + installed binary — the docs changelog listed v2.1.163 with **no lag this time**. A **managed-settings + plugins + hooks + permission-rules + `claude agents` UX/bugfix** release (~21 bullets). Each headline item checked against the statusline stdin schema:

- **`requiredMinimumVersion` / `requiredMaximumVersion`** managed settings — Claude Code refuses to start if its version is outside the allowed range. These are *managed-settings* (admin policy) keys, **not** statusline stdin fields.
- **`/plugin list`** command (with `--enabled`/`--disabled` filters) — a CLI command, no JSON impact.
- **Hooks: `hookSpecificOutput.additionalContext`** — Stop and SubagentStop hooks may now *return* this to give Claude feedback and keep the turn going without being labeled a hook error. **Critical distinction**: this is hook **output** (returned BY a hook), not part of the JSON piped TO the statusline — same class as the v2.1.145 `background_tasks`/`session_crons` hook-*input* fields and the v2.1.162 `waitingFor` CLI-subcommand field: a "new JSON field" that is **not** statusline stdin and is non-actionable.
- **`CLAUDE_CODE_SESSION_ID` now passed to stdio MCP servers** on `--resume` (the same value hooks/Bash already receive) — an env var delivered to *MCP server* subprocesses, **not** to statusline commands. (Contrast v2.1.153's `COLUMNS`/`LINES`, which *are* delivered to statusline commands and which the responsive-width system consumes.)
- Skills `$` escape syntax (literal `$` before a digit); `/btw` "c to copy" clipboard shortcut; plus ~14 bug fixes (`claude -p` hang on never-exiting background command, `claude -p` Bedrock/Vertex/Foundry `CI=true` key error, the `$TMPDIR` override regression from 2.1.154, Windows EEXIST session-env dir under OneDrive/read-only, org-managed permission-rule startup race on a fresh config dir, `claude agents` reattach losing background tasks after an update, agent-view Esc hang/misalignment, dropped paste-end-marker keyboard lockup, hook `if: "Bash(...)"` now matching subshell/backtick commands, `$HOME`-path deny rules, stray "(no content)" transcript line after closing `/mcp`/`/plugins` dialogs, background-update cold-restart). All CC-internal — none touch statusline stdin.

A grep of the statusline codebase confirms it references **none** of the new identifiers (`requiredMinimumVersion`, `requiredMaximumVersion`, `hookSpecificOutput`, `additionalContext`, `CLAUDE_CODE_SESSION_ID`). Opus 4.8 (`claude-opus-4-8`, $5/$25, v2.1.154) remains the newest model, already priced in `lib/cost/pricing.sh`.

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.6 → **v2.25.7**, docs-only). **Statusline fully compatible through v2.1.163 via feature detection** — verified by render simulation against the v2.1.163 JSON blob (Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output, `v2.1.163` shown, `Claude Opus 4.8`, `Ctx 12%` (1M window), native `rate_limits` `5h:24% • 7d:41%` (zero network), `VIM:VISUAL`, exit 0. (The full 9-line render hit the documented pre-existing prayer/IP-geolocation network hang — the sandbox firewalls the outbound `ip-api.com` curl, which has no effective internal timeout in this code path; it is 100% orthogonal to schema handling and zero code changed, so the schema-driven components were rendered in isolation via a `DISPLAY_LINES=1` component override.) Local full suite (`npm test`): **1074 ok / 42 not-ok** (real npm exit = 1), all 42 the known-environmental set — 29 in `test_prayer_auto_location.bats` + 6 in `test_prayer_functions.bats` (the `create_mock_command` `mock_bin/` harness cascade + network-blocked IP-geolocation/GPS/connectivity), 4 `test_cache_integration.bats` (XDG/git temp-dir + `migrate_legacy_cache` BW01), 2 `test_full_statusline.bats` (in-session MCP skew) — **zero** schema/pricing/render/responsive/rate_limit failures, none related to v2.1.163, which changes zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.163"`.

## v2.1.164 (never released) + v2.1.165 (5 Jun 2026) — maintenance "bug fixes and reliability improvements" (docs-only, target)

**v2.1.164 was never published — a skipped version number.** `npm view @anthropic-ai/claude-code@2.1.164` → hard **E404 "No match found"**; absent from the `versions` array, the `time` field, GitHub releases (gap 163→165), and both changelogs (docs + raw `CHANGELOG.md`). Same class as the previously-skipped v2.1.151 and v2.1.155. There is nothing to integrate for 164; the real jump is **v2.1.163 → v2.1.165**.

**v2.1.165** — npm `latest` AND `next` dist-tag (`{ latest: 2.1.165, next: 2.1.165 }` at research time; v2.1.166 had already begun shipping on `next` as a canary by 2026-06-05 19:01 UTC — out of scope for this bump, flagged for the next run); installed CC binary = 2.1.165 (`claude --version`). **The promoted public `latest` release**, with cross-source agreement across the npm registry + raw GitHub `CHANGELOG.md` + code.claude.com docs changelog + GitHub release body + installed binary — no lag this time.

**The entire v2.1.165 changelog / GitHub release body is one line**, verbatim and identical across all three official sources: *"Bug fixes and reliability improvements."* No model, schema, env-var, or render details are attached. The shipped npm package is only a thin installer wrapper (`install.cjs`, `cli-wrapper.cjs`, `sdk-tools.d.ts`, `package.json` — no bundled `cli.js` or `CHANGELOG.md`), and `sdk-tools.d.ts` contains zero statusline-schema type references, so there is no additional schema surface to inspect there. From a statusline-consumer standpoint it is fully transparent — same class as v2.1.159 ("internal infrastructure improvements"). Opus 4.8 (`claude-opus-4-8`, $5/$25, v2.1.154) remains the newest model, already priced in `lib/cost/pricing.sh`.

**Zero new/changed/removed JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.7 → **v2.25.8**, docs-only). **Statusline fully compatible through v2.1.165 via feature detection** — verified by render simulation against the v2.1.165 JSON blob (Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `v2.1.165` shown, `Claude Opus 4.8`, `Ctx 12%` (1M window), native `rate_limits` `5h:24% • 7d:41%` (zero network), `VIM:VISUAL`, exit 0. (The full 9-line render again hit the documented pre-existing prayer/IP-geolocation network hang — the sandbox firewalls the outbound `ip-api.com` curl, which has no effective internal timeout in this code path; `gtimeout` killed it at EXIT=124. It is 100% orthogonal to schema handling and zero code changed, so the schema-driven components were rendered in isolation via a `DISPLAY_LINES=1`/`LINE1_COMPONENTS` no-network component override.) Local full suite (`npm test`): **1074 ok / 42 not-ok** (1116 of 1118 executed; real npm exit = 1 — the background task-notification's "exit code 0" was `tail`'s exit per the documented pipe-masking gotcha; true exit read from the appended `EXIT_CODE=` log line), all 42 the known-environmental set — the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP skew — **zero** schema/pricing/render/responsive/rate_limit failures, none related to v2.1.165, which changes zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.165"`.

## v2.1.166 (6 Jun 2026) — feature + bugfix (fallbackModel, deny-rule globs, cross-session auth; docs-only, target)

npm `latest` AND `next` dist-tag (`{ latest: 2.1.166, next: 2.1.166 }`); installed CC binary = 2.1.166 (`claude --version`). **The promoted public `latest` release** — cross-source agreement across the npm registry + raw GitHub `CHANGELOG.md` + GitHub release body + installed binary. The code.claude.com docs changelog lagged one version (still capped at v2.1.165 at research time — the documented docs-lags-npm pattern), but the GitHub releases page and raw `CHANGELOG.md` already carried the v2.1.166 body verbatim and agreed.

Unlike the preceding maintenance one-liners (v2.1.159 "internal infrastructure improvements", v2.1.165 "bug fixes and reliability improvements"), v2.1.166 is a **feature + bugfix** release (~21 bullets). Each headline item checked against the statusline stdin schema:

- **`fallbackModel` setting / `--fallback-model` flag** — up to three fallback models tried when the primary is overloaded; `--fallback-model` now also applies to interactive sessions, with a one-shot auto-retry on the fallback for unexpected non-retryable API errors. A **settings.json / CLI** option, **not** a stdin field — it does not change the shape of `model.id` / `model.display_name` (those still report the actually-selected model).
- **Glob support in deny-rule tool-name position** (`"*"` denies all tools) — a **permission-rule config** change, unrelated to the `mcp.servers` stdin array (which CC does not populate; the statusline parses MCP from the transcript).
- **Hardened cross-session messaging** — relayed `SendMessage` messages no longer carry user authority. Inter-session auth, **no stdin surface**.
- **Thinking-token toggle** (`MAX_THINKING_TOKENS=0`, `--thinking disabled`, per-model toggle) — a **behavior control via env var / flag**; it does not alter the `thinking.enabled` stdin field's schema (the boolean still appears as before, reflecting the resulting state).
- Remaining ~17 bullets are bugfixes — JetBrains terminal flicker, Kitty-protocol Shift+non-ASCII key drops, orphaned `--bg-pty-host` 100% CPU on macOS, `claude agents` TUI input fixes, managed-settings enforcement edge cases, background agents crash-looping inside git worktrees. All CC-internal — none touch statusline stdin.

A grep of the statusline codebase confirms it references **none** of the new identifiers (`fallbackModel`, `--fallback-model`). Opus 4.8 (`claude-opus-4-8`, $5/$25, v2.1.154) remains the newest model, already priced in `lib/cost/pricing.sh`; no new model or pricing in this release.

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.8 → **v2.25.9**, docs-only). **Statusline fully compatible through v2.1.166 via feature detection** — verified by isolated render against the v2.1.166 JSON blob (Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `🧠 Claude Opus 4.8 │ Ctx: 12% │ Limit: 5h:24% • 7d:41% │ VIM:VISUAL`, native `rate_limits` zero-network, exit 0; a second isolated render via `version_display` confirmed the statusline picks up `version:2.1.166` straight from stdin (`v2.1.166` shown), exit 0. (The full 9-line render again hit the documented pre-existing prayer/IP-geolocation network hang — the sandbox firewalls the outbound `ip-api.com` curl, which has no effective internal timeout in this code path; `gtimeout` killed it at EXIT=124 even with prayer+location disabled. It is 100% orthogonal to schema handling and zero code changed, so the schema-driven components were rendered in isolation via a `DISPLAY_LINES=1`/`LINE1_COMPONENTS` no-network override.) Local full suite (`npm test`): **1073 ok / 43 not-ok** (1116 of 1118 executed, 2 pre-existing skips; real npm exit = 1), all 43 the known-environmental set — the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP skew — **zero** schema/pricing/render/responsive/rate_limit failures, none related to v2.1.166, which changes zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.166"`.

## v2.1.167 (6 Jun 2026) — maintenance "bug fixes and reliability improvements" (docs-only, target)

npm `latest` AND `next` dist-tag (`npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.167, next: 2.1.167 }`); installed CC binary = 2.1.167 (`claude --version`). **The promoted public `latest` release** — cross-source agreement across the npm registry + raw GitHub `CHANGELOG.md` + code.claude.com docs changelog + GitHub release body + installed binary, with no lag this time.

**The entire v2.1.167 changelog / GitHub release body is one line**, verbatim and identical across all three official sources: *"Bug fixes and reliability improvements"* — the exact same boilerplate shipped for the v2.1.165 maintenance release. No model, schema, env-var, or render details are attached. A binary `strings` scan of the installed `2.1.167` Mach-O surfaces no new stdin-schema field tokens (all documented fields — `current_dir`, `context_window`, `rate_limits`, `five_hour`/`seven_day`, `used_percentage`, `exceeds_200k_tokens`, `review_state`, `git_worktree` — present at expected counts; `exceeds_1m_tokens` still **absent**, so no new 1M threshold marker). From a statusline-consumer standpoint it is fully transparent — same class as v2.1.159 ("internal infrastructure improvements") and v2.1.165 ("bug fixes and reliability improvements"). Opus 4.8 (`claude-opus-4-8`, $5/$25, v2.1.154) remains the newest model, already priced in `lib/cost/pricing.sh`.

The substantive feature/bugfix work — `fallbackModel` / `--fallback-model`, deny-rule tool-name globs, cross-session-message auth hardening, the thinking-token toggle — all belongs to the preceding **v2.1.166** release (already integrated), none of which touched the stdin schema either. v2.1.164 remains a skipped/unpublished version number (npm E404, like v2.1.151/v2.1.155); the real jump from the last bump is v2.1.166 → v2.1.167.

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.9 → **v2.25.10**, docs-only). **Statusline fully compatible through v2.1.167 via feature detection** — verified by a **full 9-line render** against the v2.1.167 JSON blob (Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `CC:2.1.167` picked up straight from stdin, `Claude Opus 4.8`, `Ctx: 12%` (1M window), native `rate_limits` `5H 24%/80% • 7DAY 41%/86%` (zero network), all nine lines (incl. prayer times + GPS location) rendered, exit 0. (Unlike the v2.1.165/v2.1.166 runs, the outbound prayer/IP-geolocation curl resolved this session, so the full statusline rendered end-to-end without needing the `DISPLAY_LINES=1` no-network isolation.) Local full suite (`npm test`): **1074 ok / 42 not-ok** (1116 of 1118 executed, 2 pre-existing skips; real npm exit = 1 — the background-task notification's "exit code 0" was the trailing `echo`'s exit per the documented pipe-masking gotcha), all 42 the known-environmental set — the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP-connectivity skew — **zero** schema/pricing/render/responsive/rate_limit failures (grep-verified), none related to v2.1.167, which changes zero code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.167"`.

## v2.1.168 (6 Jun 2026) — maintenance "bug fixes and reliability improvements" (docs-only, target)

npm `latest` AND `next` dist-tag (`npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.168, next: 2.1.168 }`); installed CC binary = 2.1.168 (`claude --version`). **The promoted public `latest` release** — cross-source agreement across the npm registry + raw GitHub `CHANGELOG.md` + code.claude.com docs changelog + GitHub release body (authored by @ashwin-ant, 06 Jun 23:41 UTC, commit `7228175`) + installed binary, with no lag this time.

**The entire v2.1.168 changelog / GitHub release body is one line**, verbatim and identical across all three official sources: *"Bug fixes and reliability improvements"* — the exact same boilerplate shipped for the v2.1.165 and v2.1.167 maintenance releases. No model, schema, env-var, or render details are attached. From a statusline-consumer standpoint it is fully transparent — same class as v2.1.159 ("internal infrastructure improvements"), v2.1.165, and v2.1.167. Opus 4.8 (`claude-opus-4-8`, $5/$25, v2.1.154) remains the newest model, already priced in `lib/cost/pricing.sh`.

v2.1.167 and v2.1.168 both shipped 6 Jun 2026 carrying the identical one-liner body — the real jump from the last bump is v2.1.167 → v2.1.168. v2.1.164 remains a skipped/unpublished version number (npm E404, like v2.1.151/v2.1.155). The substantive feature/bugfix work (`fallbackModel` / `--fallback-model`, deny-rule tool-name globs, cross-session-message auth hardening, the thinking-token toggle) all belongs to the earlier **v2.1.166** release (already integrated), none of which touched the stdin schema.

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.10 → **v2.25.11**, docs-only). **Statusline fully compatible through v2.1.168 via feature detection** — verified by a **full 9-line render** against the v2.1.168 JSON blob (Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `CC:2.1.168` picked up straight from stdin, `Claude Opus 4.8`, `Ctx: 12%` (1M window), native `rate_limits` `5H 24%/80% • 7DAY 41%/86%` (zero network), all nine lines (incl. prayer times + GPS location Bekasi + `MCP:34/34`) rendered, exit 0 — the outbound prayer/IP-geolocation curl resolved this session (as in the v2.1.167 run), so no `DISPLAY_LINES=1` no-network isolation was needed. Local full suite (`npm test`): **1073 ok / 43 not-ok** (1116 of 1118 executed, 2 pre-existing skips; real npm exit = 1 — captured via the `{ npm test; echo EXIT=$?; } > log 2>&1` wrapper, since the background-task notification's "exit code 0" is the wrapper's own exit per the documented pipe-masking gotcha), all 43 the known-environmental set — the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP-connectivity skew — **zero** schema/pricing/render/responsive/rate_limit failures (grep-verified), none related to v2.1.168, which changes zero code. 43 vs the v2.1.167 run's 42 = run-to-run variance in the environmental cascade. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.168"`.

## v2.1.169 (8 Jun 2026) — feature + bugfix (--safe-mode, /cd, disableBundledSkills, custom-statusline footer-hint fix; docs-only, target)

npm `latest` AND `next` dist-tag (`npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.169, next: 2.1.169 }`); installed CC binary = 2.1.169 (`claude --version`). **The promoted public `latest` release** — cross-source agreement across the npm registry + raw GitHub `CHANGELOG.md` + code.claude.com docs changelog + GitHub release body (authored by @ashwin-ant, 08 Jun 2026 21:57 UTC, commit `f967b36`) + installed binary, with no lag this time.

Unlike the preceding maintenance one-liners (v2.1.165/v2.1.167/v2.1.168, all *"Bug fixes and reliability improvements"*), v2.1.169 is a substantial **feature + bugfix release (~31 bullets)** — closer in shape to v2.1.166. The changelog body is byte-identical across all three official sources (only `*` vs `-` bullet-marker rendering differs). Each headline item checked against the statusline stdin schema:

- **`--safe-mode` flag / `CLAUDE_CODE_SAFE_MODE` env var** — a CC-process security/config control, **not** a stdin field.
- **`/cd` command** — change the working directory mid-session without breaking the prompt cache. A CLI/REPL command; the resulting cwd still surfaces through the existing `workspace.current_dir` stdin field (no schema change).
- **`disableBundledSkills` setting / `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` env var** — settings/env config for skill auto-loading, **no stdin surface**.
- **`API_FORCE_IDLE_TIMEOUT` env var** — restores a 5-minute Vertex/Foundry idle timeout; backend/transport config, not consumed by the statusline.
- **`claude agents --json` gains `--all` flag + `id`/`state` fields** — these new JSON fields live in the **`claude agents --json` CLI subcommand output**, *not* the statusline stdin blob (the same trap as v2.1.145 `background_tasks`, v2.1.162 `waitingFor`, v2.1.163 `hookSpecificOutput.additionalContext`). The statusline never reads them.
- **Enterprise managed-MCP-policy enforcement fixes** — admin/policy surface, unrelated to the `mcp.servers` stdin array (which CC does not populate; the statusline parses MCP from the transcript).
- **"CLAUDE.md is too long" warning threshold now scales with the model context window** — an editor-side UX warning, no stdin surface.
- Remaining ~22 bullets are bugfixes (reduced CPU during streaming/spinner, Windows/WSL/Remote-Control/background-session/plugin fixes) — all CC-internal.

**The one genuinely statusline-adjacent item is a CC-side render fix:** *"Fixed footer hints (e.g. 'esc to interrupt') not showing for users with a custom statusline."* This is a **fix in Claude Code itself that benefits** custom-statusline users (footer hints were being suppressed when a custom statusline was configured) — it requires **zero changes to the statusline script**. A grep of the statusline codebase confirms it references none of the new identifiers (`--safe-mode`, `CLAUDE_CODE_SAFE_MODE`, `disableBundledSkills`, `API_FORCE_IDLE_TIMEOUT`). Opus 4.8 (`claude-opus-4-8`, $5/$25, v2.1.154) remains the newest model, already priced in `lib/cost/pricing.sh`; no new model or pricing in this release.

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.25.11 → **v2.25.12**, docs-only). **Statusline fully compatible through v2.1.169 via feature detection** — verified by a **full 9-line render** against the v2.1.169 JSON blob (Opus 4.8 + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `CC:2.1.169` picked up straight from stdin, `Claude Opus 4.8`, `Ctx: 12%` (1M window), native `rate_limits` `5H 24%/80% • 7DAY 41%/86%` (zero network), all nine lines (incl. prayer times + GPS location + `MCP:27/27`) rendered, exit 0 — the outbound prayer/IP-geolocation curl resolved this session (3rd clean run straight after v2.1.167/v2.1.168), so no `DISPLAY_LINES=1` no-network isolation was needed. Local full suite (`npm test`): **1074 ok / 42 not-ok** (1116 of 1118 executed, 2 pre-existing skips; real npm exit = 1 — captured via the `{ npm test; echo EXIT=$?; } > log 2>&1` wrapper, since the background-task notification's "exit code 0" is the wrapper's own exit per the documented pipe-masking gotcha), all 42 the known-environmental set — the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP-connectivity skew — **zero** schema/pricing/render/responsive/rate_limit failures (grep-verified), none related to v2.1.169, which changes zero statusline code. 42 matches the v2.1.167 run (vs the v2.1.168 run's 43) = run-to-run variance in the environmental cascade. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.169"`.

## v2.1.170 (9 Jun 2026) — Claude Fable 5 launch + new $10/$50 pricing tier (CODE: pricing, MINOR)

npm `latest` AND `next` dist-tag (`npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.170, next: 2.1.170 }`); installed CC binary = 2.1.170 (`claude --version`). The promoted public `latest` release — corroborated across the npm registry, the code.claude.com docs changelog, the GitHub release body, and the Anthropic platform pricing page.

**This breaks the docs-only streak.** Unlike v2.1.155–v2.1.169 (maintenance + feature releases that touched no statusline-facing surface), v2.1.170 ships a **brand-new top-tier model — Claude Fable 5** — at a **new pricing tier the statusline did not know**, which *requires* a cost-tracking code change. The entire changelog body is just two bullets:

> - Introducing Claude Fable 5: a Mythos-class model that we've made safe for general use. Fable's capabilities exceed those of any model we've ever made generally available. Update to version 2.1.170 for access.
> - Fixed sessions not saving transcripts (and not appearing in --resume) when launched from the VS Code integrated terminal or any shell that inherited Claude Code environment variables.

Each item checked against the statusline:

- **Claude Fable 5 (`claude-fable-5`)** — new top-tier model. **New pricing: $10 in / $50 out per MTok** (5m cache write $12.50 = 1.25×, 1h cache write $20.00 = 2×, cache read $1.00 = 0.1×; 5-col value `10.00 50.00 12.50 20.00 1.00`). This is **2× the Opus 4.6/4.7/4.8 tier** ($5/$25) and a tier `lib/cost/pricing.sh` had never seen. Pricing confirmed authoritatively via the bundled `claude-api` model catalog ($10/$50) and independently by changelog research. 1M context at standard pricing; no `exceeds_1m_tokens` field (the `exceeds_200k_tokens` marker is unchanged). Real transcripts emit the clean bare id `claude-fable-5` (the `[1m]` 1M-selector suffix, as with Opus, is a CLI selector that never reaches the transcript/pricing path).
- **VS Code transcript-saving bugfix** — a CC-side fix (sessions launched from the VS Code integrated terminal, or any shell inheriting CC env vars, were not persisting transcripts). No statusline change; if anything it *restores* transcript data that the statusline's transcript-fallback paths (context %, MCP parsing, cost calc) depend on.

**The required fix (the bare-ID-fallback bug class, fourth occurrence):** a `claude-fable-5` transcript entry would otherwise fall through the `case`/awk `*` default to **Sonnet rates ($3/$15)** — a ~3.3× undercount on both input and output. This is the identical bug already fixed for Opus 4.6 (v2.24.0), 4.7 (v2.24.1), and 4.8 (v2.25.0). Fix applied in **v2.26.0**:
- `lib/cost/pricing.sh` shell `case`: new dedicated tier block `claude-fable-5|claude-fable-5-*) → "10.00 50.00 12.50 20.00 1.00"` (a **new tier**, NOT lumped with the Opus $5/$25 block).
- `lib/cost/pricing.sh` `get_awk_pricing_block()`: `p["claude-fable-5"] = "10.00 50.00 12.50 20.00 1.00"` (bare key only — no dated variant is documented, matching the Opus 4.8 precedent).
- Tests: **+4 unit** (`tests/unit/test_pricing.bats` — bare ID, wildcard dated ID, distinct-tier guard against the Sonnet fallback, awk-block presence) and **+5 integration** (`tests/integration/test_pricing_integration.bats` — 1M each of input→$10, output→$50, cache-read→$1, 5m-write→$12.50, 1h-write→$20, exercising the full jq→awk pipeline).

**Sibling model Mythos 5** (announced alongside Fable 5, same $10/$50 tier, limited-availability/not GA) is **deliberately deferred** — it is absent from the authoritative `claude-api` model catalog and extremely unlikely to appear in real transcripts; encoding an unverified model ID/price would violate the "never guess model IDs" rule. If `claude-mythos-5` ever surfaces in a transcript it falls to the Sonnet default until a future update adds it (logged here rather than silently capped).

**No new/changed/removed statusline-stdin JSON fields, no new env vars to statusline, no render changes** — but **one new model + one new pricing tier (code change)** → **MINOR** bump (v2.25.12 → **v2.26.0**), matching how Opus 4.8 (v2.25.0) was handled. **Statusline fully compatible through v2.1.170** — verified by **full 9-line renders** against v2.1.170 JSON blobs for both `claude-fable-5` (renders `🔮 Claude Fable 5` — dedicated crystal-ball icon, added in v2.26.0; see below) and `claude-opus-4-8` (control, `🧠 Claude Opus 4.8`): clean output, `CC:2.1.170` straight from stdin, `Ctx: 12%` (1M window), native `rate_limits`, all nine lines, exit 0. Pricing suites in isolation: **unit 50/50, integration 17/17** (the 9 new Fable 5 tests included). Local full suite (`npm test`): **1074 ok / 42 not-ok** (1116 of 1118 executed; real exit = 1), all 42 the known-environmental set (mock_bin harness cascade through prayer/GPS/location/IP-geolocation/connectivity, cache XDG/migrate_legacy_cache BW01, in-session MCP skew) — **zero pricing/cost/schema/render failures** (grep-verified). CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.170"`.

**Dedicated Fable 5 icon (v2.26.0).** The flagship initially rendered with the generic `🤖` default (Fable hit the `*)` fallback in `get_model_emoji`). Added a **🔮 crystal-ball icon** — thematically fitting for a "Fable"/"Mythos-class" model and distinct from Opus's `🧠`. Mirrors the `opus` emoji across all five of its locations: `get_model_emoji` case (`lib/display.sh`), `CONFIG_FABLE_EMOJI` default (`lib/config/defaults.sh`), export (`lib/config/constants.sh`), `emojis.fable` schema entry (`lib/config/schema_validator.sh`), and `examples/Config.toml`. Model emojis are intentionally not wired through `extract.sh` (component emojis are; model emojis are default/ENV only — matched opus exactly, no behavior change). New `tests/unit/test_model_emoji.bats` (+7) covers Fable→🔮, the not-`🤖` guard, and Opus/Sonnet/Haiku/default regressions (previously `get_model_emoji` had zero direct test coverage). Render-verified: `🔮 Claude Fable 5`.

## v2.1.172 (10 Jun 2026) — feature + bugfix (agent nesting, Bedrock region resolution, model-picker/permission-rule fixes; docs-only, target)

npm `latest` AND `next` dist-tag (`npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.172, next: 2.1.172 }`); installed CC binary = 2.1.172 (`claude --version`). **The promoted public `latest` release** — npm publish 2026-06-10T17:55Z, GitHub release published 2026-06-10T20:44Z; the GitHub release body and raw `CHANGELOG.md` are verbatim-identical (31 bullets). The code.claude.com docs changelog still capped at v2.1.170 at research time — the known docs-lag pattern; npm + raw GitHub `CHANGELOG.md` are the source of truth (docs.claude.com now 301-redirects to code.claude.com).

**v2.1.171 was never published** (npm E404 class — absent from `npm view versions`, no GitHub release, no changelog entry anywhere; the version list jumps 2.1.170 → 2.1.172). It joins the v2.1.151/v2.1.155/v2.1.164 skip list. The real jump from the last bump is v2.1.170 → v2.1.172.

Unlike the maintenance one-liners (v2.1.165/v2.1.167/v2.1.168), v2.1.172 is a substantial **feature + bugfix release (31 bullets)** — same shape as v2.1.169. Each headline item checked against the statusline stdin schema:

- **Sub-agents can now spawn their own sub-agents (up to 5 levels deep)** — agent orchestration; doesn't change the shape of the `agent.name` stdin field the `agent_display` component renders.
- **Bedrock reads the AWS region from `~/.aws` config files when `AWS_REGION` isn't set** (AWS SDK precedence; `/status` shows where the region came from) — provider config read *by* CC, no stdin surface.
- **`model` attribute added to the `claude_code.lines_of_code.count` OTEL metric** — telemetry surface, **not** statusline stdin (same class as the v2.1.161 OTEL metric labels).
- **`availableModels` enforcement fixes** (subagent model overrides, dispatch model picker, advisor model; allowlists no longer hide the `/model` picker's Opus/Sonnet 1M rows when entries use version-specific IDs like `claude-opus-4-8`; Bedrock picker no longer offers unserved models) — settings/UI surface; `claude-opus-4-8` appears only as an example ID, no new model.
- **Fixed model IDs getting a doubled 1M-context suffix (e.g. `[1M][1m]`) when `ANTHROPIC_DEFAULT_OPUS_MODEL` already includes one** — value-hygiene fix: stdin `model.id` could previously carry the malformed doubled suffix in that env-override edge case; now normalized. The statusline was unaffected either way — `model_info` renders `display_name`, and pricing matches transcript `message.model` (clean bare IDs), never stdin `model.id`. Passive benefit, zero action.
- **Fixed 1M-context sessions without usage credits getting permanently stuck — the session now automatically compacts back under the standard context limit** — passive behavioral note: `context_window.context_window_size`/percentages can now legitimately drop mid-session; the statusline reads these dynamically per invocation, absorbing it automatically.
- **Permission-rule wildcard fixes** (`WebFetch(domain:*.example.com)` subdomain matching in allow/deny/ask; mid-pattern file wildcards like `Read(secrets-*/config.json)` no longer rejected at startup) — permission engine, no stdin surface.
- **`/plugin` marketplace search bar** + plugin-browser cursor/Esc fixes, `/model` suggestion rendering in `claude agents` dispatch, up-arrow prompt-history fix in subagent tabs, agents-view spinner/stuck-state fixes, background-agent project-settings isolation fix, EAUTH attach fix — CLI/TUI/daemon surface.
- **Perf work** — long-conversation message-normalization removal, fewer UI re-renders while subagents run, `/goal` status chip no longer re-rendering at 5 Hz idle, Claude-in-Chrome tools loading in one batched call — CC-internal; the `/goal` chip and shortened "/rc active" Remote Control footer indicator are CC's own footer/TUI, not the custom-statusline area or invocation cadence.
- Remaining bullets (memory-recall `CLAUDE_MEMORY_STORES` in remote sessions, workflow-validation false positives on `Date.now()`/`Math.random()` mentions, Windows mouse tracking, VS Code PowerShell rendering, `/code-review` ultra visibility, Usage Policy refusal message, `/loop` remote-session promotion) — all CC-internal.

**Zero mentions of "statusline"/"status line" anywhere in the changelog** (grep-verified: 0 hits). No new models or pricing — Fable 5 (`claude-fable-5`, $10/$50, v2.1.170) remains the newest model, already priced in `lib/cost/pricing.sh`; sibling Mythos 5 remains absent from the authoritative model catalog (still deferred).

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars** → **PATCH** bump (v2.26.0 → **v2.26.1**, docs-only). **Statusline fully compatible through v2.1.172 via feature detection** — verified by a **full 9-line render** against the v2.1.172 JSON blob (**`claude-fable-5`** + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `🔮 Claude Fable 5` (the v2.26.0 crystal-ball icon), `CC:2.1.172` picked up straight from stdin, `Ctx: 12%` (1M window), native rate_limits `5H 24%/80% • 7DAY 41%/86%` (zero network), all nine lines (incl. prayer times + `📍 Loc: Jakarta` + `MCP:27/27`) rendered, exit 0. Local full suite (`npm test`): **1090 ok / 42 not-ok** (1132 of 1134 executed, 2 pre-existing skips; real npm exit = 1 via the `{ npm test; echo EXIT=$?; } > log 2>&1` wrapper — the expected total rose 1118 → 1134 from v2.26.0's +16 tests, and ok rose 1074 → 1090, exactly the new pricing + emoji tests all passing), all 42 the known-environmental set — the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP-connectivity skew — **zero** schema/pricing/render/responsive/rate_limit/emoji failures (grep-verified), none related to v2.1.172, which changes zero statusline code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.172"`.

## v2.1.173 (11 Jun 2026) — Fable 5 `[1m]` suffix normalization + Windows sandbox-warning fix (docs-only, target)

npm `latest` dist-tag (`npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.173, next: 2.1.174 }`); installed CC binary = 2.1.173 (`claude --version`). npm publish 2026-06-11T02:09:50Z, GitHub release published 11 Jun 05:41. **All three changelog sources are verbatim-identical** (docs changelog at code.claude.com — the 301-redirect target of docs.claude.com, established in the v2.1.172 cycle — GitHub release body, and raw `CHANGELOG.md`): a **2-bullet bugfix release**. Note: **v2.1.174 exists on the npm `next` channel only** (published 2026-06-11T22:27:52Z, no changelog entry in any source) — the same canary pattern as v2.1.160; out of scope for this target.

The two bullets, each checked against the statusline:

- **"Fixed Fable 5 model names with a `[1m]` suffix not being normalized — Fable 5 includes 1M context by default, so the suffix is now stripped automatically."** The direct sibling of v2.1.172's doubled-`[1M][1m]` suffix fix: a user-forced `claude-fable-5[1m]` (e.g. via `ANTHROPIC_MODEL`) previously survived un-normalized because Fable 5 is 1M-by-default; now CC strips it, so stdin `model.id` is always the clean `claude-fable-5`. **Passive value hygiene, zero statusline action**: the `model_info` component renders `model.display_name` (never the id), and pricing keys on transcript `message.model`, which the API returns as the clean bare id (the `[1m]` selector form never reaches the pricing path — established in v2.25.0/v2.26.0). Bonus in the statusline's favor: this CC fix **closes the one theoretical leak** — a `claude-fable-5[1m]` value would *not* have matched the `claude-fable-5`/`claude-fable-5-*` patterns in `lib/cost/pricing.sh` and would have fallen to the Sonnet default; that input can now never occur.
- **"Fixed a spurious 'sandbox dependencies missing' startup warning on Windows when sandbox was enabled in settings."** A Windows-only CC startup/TUI fix — no statusline relevance (statusline platforms are macOS/Linux).

No "new JSON field" trap this release — the changelog contains no JSON fields of any kind. No new models or pricing — Fable 5 (`claude-fable-5`, $10/$50, v2.1.170) remains the newest model, already priced in `lib/cost/pricing.sh` since v2.26.0; sibling Mythos 5 remains absent from the authoritative model catalog (still deferred).

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars, zero render changes** → **PATCH** bump (v2.26.1 → **v2.26.2**, docs-only). **Statusline fully compatible through v2.1.173 via feature detection** — verified by a **full render** against the v2.1.173 JSON blob (**`claude-fable-5`** + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `🔮 Claude Fable 5` (the v2.26.0 crystal-ball icon), `CC:2.1.173` picked up straight from stdin, `Ctx: 12%` (1M window), native rate_limits `5H 24%/80% • 7DAY 41%/86%` (zero network), all lines rendered (incl. prayer times + `📍 Loc: Southeast Asia` + `MCP:27/27`), zero stderr, exit 0 — all four markers grep-verified individually (6th consecutive hang-free render). Local full suite (`npm test`): **1090 ok / 42 not-ok** (1132 of 1134 executed, 2 pre-existing skips; real npm exit = 1 via the `{ npm test; echo EXIT=$?; } > log 2>&1` wrapper) — **identical counts to the v2.1.172 baseline run**, all 42 the known-environmental set (the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP-connectivity skew) — **zero** schema/pricing/render/responsive/rate_limit/emoji/fable failures (grep-verified), none related to v2.1.173, which changes zero statusline code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.173"`.

## v2.1.174–v2.1.176 (12 Jun 2026) — three same-day feature/settings/bugfix releases, all docs-only (target v2.1.176)

npm `latest` dist-tag (`npm view @anthropic-ai/claude-code dist-tags` → `{ stable: 2.1.153, latest: 2.1.176, next: 2.1.176 }`); installed CC binary = 2.1.176 (`claude --version`). All three published within ~21 hours — npm publish times: v2.1.174 2026-06-11T22:27Z (late-evening US, hence the changelog's "June 12" date), v2.1.175 2026-06-12T02:10Z, v2.1.176 2026-06-12T19:45Z — **all promoted to the public `latest` tag** (none a `next`-only canary). No v2.1.177 yet (npm E404). Docs-changelog lag note: at research time `code.claude.com` carried v2.1.174 + v2.1.175 but not yet v2.1.176; v2.1.176's entry was authoritative only on GitHub raw `CHANGELOG.md`. Verbatim bullet text captured from raw `CHANGELOG.md`.

**Canary-flag correction**: the v2.1.173 cycle flagged v2.1.174 as a `next`-only, no-changelog canary (the v2.1.160 pattern) because at that moment it was published to `next` alone with no changelog. That call is now **superseded — v2.1.174 was promoted to `latest` with a full 13-bullet changelog**. So a `next`-ahead-of-`latest` version is *sometimes* a permanent skip (v2.1.160, never promoted) and *sometimes* just an early `next` publish that lands on `latest` within a day (v2.1.174). The "check `dist-tags` each cycle, don't pin a public release to the installed binary" lesson stands; the specific "v2.1.174 = canary" claim has been corrected in the memory log.

Each version checked bullet-by-bullet against the statusline stdin schema:

### v2.1.174 — feature + bugfix (13 bullets)
- **`wheelScrollAccelerationEnabled` setting** — disables mouse-wheel scroll acceleration in fullscreen mode; a TUI input setting, not stdin.
- `/model` picker fixes (Default-resolved family now shown as its own Opus/Sonnet row per plan tier; hardcoded-Sonnet-label fix when `ANTHROPIC_DEFAULT_SONNET_MODEL` pins another Sonnet), "Fable 5 is now consuming usage credits" banner suppressed for enterprise usage-based-billing accounts, Bedrock GovCloud (`us-gov-*`) inference-profile-prefix fix (was deriving `global`, causing 400s on derived model IDs), background sessions no longer inheriting another session's `ANTHROPIC_*` provider env (gateway URL, custom headers, `/model` aliases) from the daemon-launching shell, macOS/Linux post-interrupt exit-pause fix, git co-author model-name fix, `/advisor` allowlist-pre-selection fix, skill hot-reload now re-announces only changed skills, Workflow `agent()` per-agent attribution-header fix, [VSCode] `/usage` dialog usage-attribution breakdown (cache misses, long context, subagents, per-skill/agent/plugin/MCP over 24h/7d), pre-warmed-worker idle-auth fix — all TUI/CLI/VSCode/provider/daemon surface.
- **Statusline impact: none.** No stdin schema, model, pricing, env-var (to statusline), or render change.

### v2.1.175 — managed-settings feature (1 bullet)
- **`enforceAvailableModels` managed setting** — when enabled, the `availableModels` allowlist also constrains the Default model (a Default resolving to a disallowed model falls back to the first allowed model), and user/project settings can no longer widen a managed list. A managed/enterprise settings.json field, not statusline stdin.
- **Statusline impact: none.**

### v2.1.176 — feature + bugfix (22 bullets)
- **`footerLinksRegexes` setting** — regex-matched link badges in **CC's own footer row** (configurable via user or managed settings). This is CC's footer (the row CC draws below the prompt), *not* the custom-statusline `statusLine` stdin schema and *not* the statusline output area. No statusline impact.
- **Session titles now generated in the conversation's language** (`language` setting to pin a specific language) — session-metadata/TUI, not stdin.
- **`availableModels` enforcement hardening** — alias model picks can no longer be redirected to a blocked model via `ANTHROPIC_DEFAULT_*_MODEL`; `/fast` now refuses to toggle when it would switch to a model outside the allowlist. Settings/CLI surface.
- **Fable 5 auto-mode fix** — *"Fixed auto mode failing on Fable 5 for organizations without Opus 4.8 enabled — the classifier now falls back to the best available Opus model."* An **operational auto-mode routing fix, not a catalog/pricing change**: `claude-fable-5` ($10/$50) and `claude-opus-4-8` ($5/$25) are both already known and priced in `lib/cost/pricing.sh` (since v2.26.0 / v2.25.0). No new model ID, no pricing change.
- Bedrock credential caching now honors the `awsCredentialExport` `Expiration` (was a fixed 1h), hook `if`-condition path patterns (`Edit(src/**)`, `Read(~/.ssh/**)`, `Read(.env)`) now match, Linux sandbox symlinked-`settings.json` fix, `/copy` + mouse-selection clipboard fixes under tmux-over-SSH, three Remote Control fixes (silent model switch on web/mobile connect, human-readable disconnect reasons, disconnect-on-account-switch), **`/cd` + worktree moves no longer leave the session reporting the previous directory's git branch**, `claude agents` back-navigation window isolation, multiple background-session fixes (`/bg` "Working" forever, PR-URL search during scheduled wakeups, `--bg -cn` name seeding, Windows network-path/resume-ID/daemon-ReadOnly), cloud-session idle-auth fix — all TUI/daemon/provider/cloud/CLI surface.
- The **`/cd`+worktree branch-reporting fix** is the one statusline-adjacent item: it corrects CC's internal session state after a working-dir change. The statusline is unaffected by design — it reads `workspace.current_dir` from stdin and recomputes git branch/status directly per invocation (the same dynamic-read that already absorbed the v2.1.169 mid-session `/cd` feature), so it always reflected the real cwd. Passive correctness, zero code change.
- **Statusline impact: none.**

No new models or pricing across the range — Fable 5 (`claude-fable-5`, $10/$50, v2.1.170) remains the newest model, already priced; sibling Mythos 5 remains absent from the authoritative model catalog (still deferred). Zero "statusline"/"status line" mentions in any of the three changelogs.

**Zero new/changed/removed statusline-stdin JSON fields, zero new model IDs, zero pricing changes, zero new statusline env vars, zero render changes** across v2.1.174–v2.1.176 → **PATCH** bump (v2.26.2 → **v2.26.3**, docs-only). **Statusline fully compatible through v2.1.176 via feature detection** — verified by a **full render** against the v2.1.176 JSON blob (**`claude-fable-5`** + 1M + `vim:VISUAL` + `effort` + `thinking` + `workspace.repo` + `pr` + native `rate_limits`): clean output — `🔮 Claude Fable 5` (the v2.26.0 crystal-ball icon), `CC:2.1.176` picked up straight from stdin, `Ctx: 12%` (1M window), native rate_limits `24%/80% • 41%/86%` (zero network), all nine lines rendered (incl. prayer times + `📍 Loc: Southeast Asia` + `MCP:27/27`), empty stderr, exit 0 — `CC:2.1.176` and `Fable 5` markers grep-verified (7th consecutive hang-free render). Local full suite (`npm test`): **1090 ok / 42 not-ok** (1132 of 1134 executed, 2 pre-existing skips; real npm exit = 1) — **identical counts to the v2.1.172/v2.1.173 baseline**, all 42 the known-environmental set (the `create_mock_command` `mock_bin/` harness cascade through prayer/GPS/location/IP-geolocation/connectivity, `test_cache_integration.bats` XDG/git temp-dir + `migrate_legacy_cache` BW01, in-session MCP-connectivity skew) — zero schema/pricing/render/responsive/rate_limit/emoji/fable failures, none related to v2.1.174–v2.1.176, which change zero statusline code. CI (Ubuntu) is the authoritative gate. Manual test command now uses `version: "2.1.176"`.
