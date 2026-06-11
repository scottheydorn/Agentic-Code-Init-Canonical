# Agentic Code Init — Canonical

A portable, tool-agnostic AI coding assistant configuration that establishes ground rules, design patterns, and MCP (Model Context Protocol) server definitions for any agentic coding tool.

## What This Is

This repository provides a **single source of truth** for how AI coding assistants should behave when working on your projects. It includes:

- **`ai-instructions.md`** — Universal coding standards, architecture patterns, API design rules, and technology preferences
- **`bootstrap.sh`** — Automated multi-agent installer that detects and configures all AI tools
- **`mcp-servers/`** — MCP server definitions with capabilities, auth requirements, and setup instructions
- **`mcp-servers/mcp-config.template.json`** — Ready-to-use template for MCP configuration

## Quick Start

### Option A: One-Line Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/scottheydorn/Agentic-Code-Init-Canonical/main/bootstrap.sh | bash
```

This will:
1. Download the latest `ai-instructions.md` to `~/.ai-instructions.md`
2. Detect which AI coding agents are installed on your system
3. Create the appropriate symlinks/config files for each detected agent
4. Report what was configured

### Option B: Clone and Run Locally

```bash
git clone https://github.com/scottheydorn/Agentic-Code-Init-Canonical.git
cd Agentic-Code-Init-Canonical
./bootstrap.sh
```

### Option C: Manual Installation

```bash
# Download canonical file
curl -fsSL https://raw.githubusercontent.com/scottheydorn/Agentic-Code-Init-Canonical/main/ai-instructions.md -o ~/.ai-instructions.md

# Create symlinks for your agents manually
mkdir -p ~/.github && ln -sf ~/.ai-instructions.md ~/.github/copilot-instructions.md
mkdir -p ~/.claude && ln -sf ~/.ai-instructions.md ~/.claude/CLAUDE.md
```

## Bootstrap Script Usage

```bash
./bootstrap.sh [OPTIONS]
```

| Option | Description |
|--------|-------------|
| `--agent <name>` | Install for a specific agent only (copilot, claude, cursor, windsurf, cline, aider, continue) |
| `--force` | Overwrite existing files without prompting (backs up originals) |
| `--dry-run` | Show what would be done without making changes |
| `--no-mcp` | Skip MCP configuration template setup |
| `--uninstall` | Remove all installed files and symlinks |

### Examples

```bash
# Install for all detected agents
./bootstrap.sh

# Install for Claude Code only
./bootstrap.sh --agent claude

# Preview what would happen
./bootstrap.sh --dry-run

# Force update everything
./bootstrap.sh --force

# Remove all installed config
./bootstrap.sh --uninstall
```

### Auto-Update

Add to your shell profile (`.zshrc` / `.bashrc`):

```bash
alias ai-sync="curl -fsSL https://raw.githubusercontent.com/scottheydorn/Agentic-Code-Init-Canonical/main/bootstrap.sh | bash"
```

Then run `ai-sync` anytime to pull the latest instructions and re-configure agents.

## Multi-Agent Architecture

```
┌─────────────────────────────────────────────────────────┐
│             GitHub Repository (Source of Truth)           │
│  github.com/scottheydorn/Agentic-Code-Init-Canonical     │
└─────────────────────────┬───────────────────────────────┘
                          │ bootstrap.sh / curl
                          ▼
┌─────────────────────────────────────────────────────────┐
│              ~/.ai-instructions.md                        │
│              (Canonical Local Copy)                       │
└────┬──────┬──────┬──────┬──────┬──────┬─────────────────┘
     │      │      │      │      │      │
     ▼      ▼      ▼      ▼      ▼      ▼
  Copilot Claude Cursor Windsurf Cline Aider
  symlink symlink  .mdc  symlink symlink yaml
```

### How Agent Detection Works

The bootstrap script checks for each agent using:
- **Command availability** — e.g., `gh` for Copilot, `claude` for Claude Code
- **Config directory presence** — e.g., `~/.cursor/`, `~/.windsurf/`

Only detected agents receive configuration. Undetected agents are silently skipped.

### Deferred Variable Prompting

MCP server credentials and other secrets are **NOT prompted at install time**. Instead:

1. The instructions file references MCP servers by name and capability
2. When you invoke a capability that requires an MCP server, the agent prompts for credentials
3. Credentials are stored in the agent's own config location (never in this repo)

This means you can install on any machine without needing all credentials upfront.

## Configure MCP Servers

```bash
# Copy the template to your MCP config location
cp mcp-servers/mcp-config.template.json ~/.copilot/mcp-config.json

# Edit and replace all <PLACEHOLDER> values with your credentials
# NEVER commit the filled-in config to source control
```

## Per-Project Overrides

Create a local file in your project root to override global defaults:

```bash
# Any of these will be picked up by their respective tools:
.ai-instructions.md      # Universal
.github/copilot-instructions.md  # GitHub Copilot
CLAUDE.md                # Claude Code
.cursorrules             # Cursor
.windsurfrules           # Windsurf
.clinerules              # Cline
AGENTS.md                # GitHub Copilot Workspace
```

## Supported AI Coding Tools

| Tool | Global Config Location | Per-Project | Detection |
|------|----------------------|-------------|-----------|
| GitHub Copilot CLI | `~/.github/copilot-instructions.md` | `.github/copilot-instructions.md` | `gh` command |
| Claude Code | `~/.claude/CLAUDE.md` | `CLAUDE.md` | `claude` command |
| Cursor | `~/.cursor/rules/ai-instructions.mdc` | `.cursorrules` | `~/.cursor/` dir |
| Windsurf | `~/.windsurf/rules/ai-instructions.md` | `.windsurfrules` | `~/.windsurf/` dir |
| Cline | `~/.cline/rules/ai-instructions.md` | `.clinerules` | `~/.cline/` dir |
| Aider | `~/.aider.conf.yml` | `.aider.conf.yml` | `aider` command |
| Continue | `~/.continue/instructions.md` | N/A | `~/.continue/` dir |

## MCP Server Reference

| Server | Description | Package/Source |
|--------|-------------|----------------|
| **azure-devops** | Azure DevOps work items, pipelines, repos, wikis | `@azure-devops/mcp` (npx) |
| **d365fo** | D365 Finance & Operations entities, metadata, reports | `d365fo-client` (uvx/PyPI) |
| **devops-bridge** | Unified ADO + Jira + Confluence | Custom Node.js server |
| **spira** | SpiraPlan project management | Custom Node.js server |

Each server definition in `mcp-servers/` includes:
- Full capability list
- Authentication method and requirements
- Setup prerequisites and install commands
- Known issues and workarounds

## Customization Guide

### Modifying Coding Standards

Edit `ai-instructions.md` to match your preferences:

- **Language preferences:** Change the priority order in "Code Style & Conventions"
- **Architecture patterns:** Update "Architecture & Design Patterns" for your stack
- **Cloud provider:** Replace Azure references if using AWS/GCP
- **ORM/Database:** Replace Drizzle/PostgreSQL references with your preferred stack
- **UI framework:** Update the "UI & Styling" section for your CSS framework

### Adding MCP Servers

1. Create a new JSON file in `mcp-servers/` following the existing format
2. Add the server entry to `mcp-config.template.json`
3. Update the MCP table in `ai-instructions.md`

### Removing Sections

If a section doesn't apply to your work, remove it entirely rather than leaving it empty. AI tools perform better with focused, relevant instructions.

## Security Notes

⚠️ **NEVER commit credentials** — The `mcp-config.template.json` contains only placeholders. Your actual credentials should live in:
- Environment variables
- Azure Key Vault (or equivalent secrets manager)
- Local config files excluded by `.gitignore`

The `.gitignore` in this repo explicitly excludes common credential file patterns.

## File Structure

```
├── README.md                          # This file
├── bootstrap.sh                       # Multi-agent bootstrap/sync script
├── version.json                       # Version manifest with SHA256 hash
├── ai-instructions.md                 # The canonical instructions file
├── mcp-servers/
│   ├── azure-devops.json              # Azure DevOps MCP server definition
│   ├── d365-finance-operations.json   # D365 F&O MCP server definition
│   ├── devops-bridge.json             # DevOps Bridge (ADO+Jira+Confluence)
│   ├── spira.json                     # SpiraPlan MCP server definition
│   └── mcp-config.template.json       # Ready-to-use config template
└── .gitignore
```

## License

MIT — Use and adapt freely for your own agentic coding workflows.
