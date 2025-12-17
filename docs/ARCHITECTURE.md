# Architecture Overview

This document provides a visual overview of the Claude Code Statusline module structure and data flow.

## Module Dependency Graph

```mermaid
graph TD
    subgraph "Entry Point"
        A[statusline.sh]
    end

    subgraph "Core Layer"
        B[core.sh]
        C[security.sh]
        D[cache.sh]
    end

    subgraph "Configuration Layer"
        E[config.sh]
        F[themes.sh]
    end

    subgraph "Data Modules"
        G[git.sh]
        H[mcp.sh]
        I[cost.sh]
        J[prayer/]
    end

    subgraph "Output Layer"
        K[components.sh]
        L[display.sh]
    end

    A --> B
    B --> C
    B --> D
    D --> C
    B --> E
    E --> F
    B --> G
    B --> H
    B --> I
    B --> J
    B --> K
    K --> L
```

## Prayer Module Structure

```mermaid
graph TD
    subgraph "Prayer System"
        P[prayer/core.sh]
        P1[prayer/location.sh]
        P2[prayer/calculation.sh]
        P3[prayer/display.sh]
        P4[prayer/timezone_methods.sh]
    end

    P --> P1
    P --> P2
    P --> P3
    P1 --> P4
```

## Data Flow

```mermaid
flowchart LR
    subgraph "Input"
        I1[JSON stdin]
        I2[Config.toml]
        I3[Environment]
    end

    subgraph "Processing"
        P1[Config Loading]
        P2[Theme Application]
        P3[Data Collection]
        P4[Component Rendering]
    end

    subgraph "Output"
        O1[1-9 Line Display]
    end

    I1 --> P1
    I2 --> P1
    I3 --> P1
    P1 --> P2
    P2 --> P3
    P3 --> P4
    P4 --> O1
```

## Atomic Components (21 Total)

| Category | Components |
|----------|------------|
| **Repository & Git** (4) | `repo_info`, `commits`, `submodules`, `version_info` |
| **Model & Session** (4) | `model_info`, `cost_repo`, `cost_live`, `reset_timer` |
| **Cost Analytics** (3) | `cost_monthly`, `cost_weekly`, `cost_daily` |
| **Block Metrics** (4) | `burn_rate`, `token_usage`, `cache_efficiency`, `block_projection` |
| **System** (2) | `mcp_status`, `time_display` |
| **Spiritual** (2) | `prayer_times`, `location_display` |

## Cache System

```mermaid
graph TD
    subgraph "Cache Hierarchy"
        C1[XDG Cache Dir]
        C2[Repository Isolation]
        C3[TTL Management]
    end

    subgraph "TTL Values"
        T1["Session: permanent"]
        T2["Claude version: 15min"]
        T3["MCP list: 2min"]
        T4["Git status: 30s"]
        T5["Branch: 10s"]
    end

    C1 --> C2
    C2 --> C3
    C3 --> T1
    C3 --> T2
    C3 --> T3
    C3 --> T4
    C3 --> T5
```

## Module Loading Order

1. **core.sh** - Base utilities, logging, error handling
2. **security.sh** - Input sanitization, path validation
3. **cache.sh** - Caching infrastructure
4. **config.sh** - TOML configuration loading
5. **themes.sh** - Color theme management
6. **git.sh** - Repository integration
7. **mcp.sh** - MCP server monitoring
8. **cost.sh** - Cost tracking via ccusage
9. **prayer/** - Islamic prayer times (optional)
10. **components.sh** - Component registry
11. **display.sh** - Final output rendering

## File Structure

```
claude-code-statusline/
├── statusline.sh           # Main entry point
├── Config.toml             # Default configuration (227 settings)
├── version.txt             # Version tracking
├── lib/
│   ├── core.sh             # Base utilities
│   ├── security.sh         # Input sanitization
│   ├── cache.sh            # Caching system
│   ├── config.sh           # TOML parsing
│   ├── themes.sh           # Color themes
│   ├── git.sh              # Git integration
│   ├── mcp.sh              # MCP monitoring
│   ├── cost.sh             # Cost tracking
│   ├── components.sh       # Component registry
│   ├── display.sh          # Output rendering
│   ├── prayer/             # Prayer time modules
│   │   ├── core.sh
│   │   ├── location.sh
│   │   ├── calculation.sh
│   │   ├── display.sh
│   │   └── timezone_methods.sh
│   └── components/         # Atomic components
│       ├── repo_info.sh
│       ├── commits.sh
│       ├── cost_*.sh
│       └── ...
├── tests/
│   ├── unit/               # Unit tests
│   ├── integration/        # Integration tests
│   └── benchmarks/         # Performance tests
└── docs/                   # Documentation
```
