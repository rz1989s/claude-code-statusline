# Claude Code Version Compatibility Notes

Per-version compatibility log for Claude Code releases from v2.1.77 through v2.1.156. The statusline uses **feature detection** (field existence), not version comparison, so it gracefully handles missing or unknown fields via the `get_json_field()` abstraction.

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

## v2.1.156 (current latest) — released, changelog pending

npm `latest` dist-tag and the installed CC release at update time, but **its public changelog has not been published** — neither the docs changelog nor the GitHub `CHANGELOG.md`/tags include v2.1.155 or v2.1.156 (the GitHub side lags the npm/binary distribution channel). No documented schema deltas exist to act on beyond v2.1.154. **Verified compatible via live render against the actual installed v2.1.156 binary**: clean multi-line output, `CC:2.1.156` shown (the statusline detects the real `claude --version` via its `external_claude_version_shared.cache`), Opus 4.8 priced at $5/$25, and the `workspace.repo`/`pr`/`rate_limits`/`effort`/`thinking` fields all handled, exit 0. The feature-detection architecture absorbs any undocumented additive fields gracefully; when Anthropic publishes the v2.1.155/v2.1.156 notes, any genuinely new fields can be folded in then.

**Statusline fully compatible through v2.1.156** — Opus 4.8 cost support added (pricing pattern + 3 new pricing tests, 46/46 pass), the COLUMNS/LINES responsive-width delivery documented, render verified against the live 2.1.156 binary. Full suite is the CI gate (Ubuntu); the local sandbox shows the same ~42 environmental failures inherited from prior updates (mock-command harness, network prayer tests, in-session MCP skew, `migrate_legacy_cache` BW01) — none related to v2.1.152–156. v2.25.0 is a **minor** bump (new model pricing support, not docs-only). Manual test command now uses `version: "2.1.156"` with `claude-opus-4-8`.
