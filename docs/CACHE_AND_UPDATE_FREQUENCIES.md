# Cache and Update Frequencies

This document details all time-related constants and update frequencies for information displayed in the Claude Code statusline.

## All Time-Related Constants

### CACHE_DURATION_* Constants (General Caching)
| Constant | Seconds | Time Period | Usage |
|---|---|---|---|
| `CACHE_DURATION_SESSION` | **0** | Never expires | Command existence checks |
| `CACHE_DURATION_PERMANENT` | **86400** | 24 hours | System info (OS, architecture) |
| `CACHE_DURATION_VERY_LONG` | **21600** | 6 hours | Claude version |
| `CACHE_DURATION_LONG` | **3600** | 1 hour | Git config, version files |
| `CACHE_DURATION_MEDIUM` | **300** | 5 minutes | MCP servers, git submodules, directory info |
| `CACHE_DURATION_SHORT` | **30** | 30 seconds | Git repo check, branches |
| `CACHE_DURATION_VERY_SHORT` | **10** | 10 seconds | Git status, current branch |
| `CACHE_DURATION_REALTIME` | **5** | 5 seconds | Current directory, file status |
| `CACHE_DURATION_LIVE` | **2** | 2 seconds | High-frequency operations |

### COST_CACHE_DURATION_* Constants (Cost Tracking)
| Constant | Seconds | Time Period | Usage |
|---|---|---|---|
| `COST_CACHE_DURATION_LIVE` | **30** | 30 seconds | Active blocks (real-time) |
| `COST_CACHE_DURATION_SESSION` | **120** | 2 minutes | Repository session cost |
| `COST_CACHE_DURATION_DAILY` | **600** | 10 minutes | Today's cost |
| `COST_CACHE_DURATION_WEEKLY` | **3600** | 1 hour | 7-day total |
| `COST_CACHE_DURATION_MONTHLY` | **7200** | 2 hours | 30-day total |

### Timeout Constants
| Constant | Default | Purpose |
|---|---|---|
| `CONFIG_MCP_TIMEOUT` | **"10s"** | MCP server operations timeout |
| `CONFIG_VERSION_TIMEOUT` | **"2s"** | Version check timeout |
| `CONFIG_CCUSAGE_TIMEOUT` | **"3s"** | Cost tracking operations timeout |
| `CACHE_CONFIG_ATOMIC_TIMEOUT` | **5s** | Cache write operations timeout |
| `CACHE_CONFIG_CLEANUP_INTERVAL` | **300s** | Cache cleanup interval |
| `CACHE_CONFIG_MAX_AGE_HOURS` | **168 hours** | Maximum cache age (7 days) |

## Comprehensive Statusline Information Update Frequencies

| Statusline Information | Cache Duration | Update Frequency | Notes |
|---|---|---|---|
| **🗂️ Directory Path** | None | **Real-time** | Always fresh, no caching |
| **🌿 Git Branch** | 30 seconds | **Every 30s** | `CACHE_DURATION_SHORT` |
| **📊 Git Status (clean/dirty)** | 30 seconds | **Every 30s** | `CACHE_DURATION_SHORT` |
| **📝 Commits Today** | None | **Real-time** | Direct git query, no caching |
| **📦 Git Submodules** | None | **Real-time** | Direct count, no explicit caching |
| **⚡ Claude Version** | 6 hours | **Every 6 hours** | `CACHE_DURATION_VERY_LONG` |
| **🔌 MCP Server List** | 5 minutes | **Every 5 minutes** | `CACHE_DURATION_MEDIUM` |
| **🔌 MCP Status (connected/total)** | 5 minutes | **Every 5 minutes** | `CACHE_DURATION_MEDIUM` |
| **💰 Session Cost** | 2 minutes | **Every 2 minutes** | `COST_CACHE_DURATION_SESSION` |
| **📅 Today's Cost** | 10 minutes | **Every 10 minutes** | `COST_CACHE_DURATION_DAILY` |
| **📊 7-Day Cost** | 1 hour | **Every hour** | `COST_CACHE_DURATION_WEEKLY` |
| **📈 30-Day Cost** | 2 hours | **Every 2 hours** | `COST_CACHE_DURATION_MONTHLY` |
| **⏱️ Active Block Cost** | 30 seconds | **Every 30 seconds** | `COST_CACHE_DURATION_LIVE` |
| **🔄 Block Reset Timer** | 30 seconds | **Every 30 seconds** | `COST_CACHE_DURATION_LIVE` |

## Update Frequency Summary

**Most Frequent (Real-time):** Directory path, commits today, submodules  
**High Frequency (≤30s):** Git branch, git status, active blocks, block reset  
**Medium Frequency (2-10min):** Session cost, today's cost  
**Low Frequency (1-6hr):** Weekly cost, monthly cost, Claude version, MCP servers  
**Rare Updates (24hr+):** System information (OS, architecture)

## Performance Optimization Strategy

The caching system is intelligently designed with different update frequencies based on data volatility:

- **Rapidly changing data** (git status, active billing) updates frequently for accuracy
- **Moderately changing data** (costs, MCP servers) uses medium-term caching for balance  
- **Stable information** (Claude version, monthly totals) is cached extensively for performance
- **System information** (OS, architecture) is cached permanently as it rarely changes

This approach ensures the statusline provides up-to-date information while maintaining excellent performance through intelligent caching strategies.

## Customization

These cache durations can be customized through:
- **TOML Configuration**: Modify `Config.toml` cache settings
- **Environment Variables**: Override with `ENV_CONFIG_*` variables
- **Direct Module Modification**: Edit cache constants in respective modules

Example environment overrides:
```bash
ENV_CONFIG_MCP_TIMEOUT=15s ./statusline.sh           # Increase MCP timeout
ENV_CONFIG_CCUSAGE_TIMEOUT=1s ./statusline.sh        # Reduce cost tracking timeout  
ENV_CONFIG_VERSION_CACHE_DURATION=3600 ./statusline.sh  # Cache Claude version for 1 hour
```