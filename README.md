# Agentic Code Init — Canonical

A portable, tool-agnostic AI coding assistant configuration that establishes ground rules, design patterns, and MCP (Model Context Protocol) server definitions for any agentic coding tool.

## What This Is

This repository provides a **single source of truth** for how AI coding assistants should behave when working on your projects. It includes:

- **`ai-instructions.md`** — Universal coding standards, architecture patterns, API design rules, and technology preferences
- **`mcp-servers/`** — MCP server definitions with capabilities, auth requirements, and setup instructions
- **`mcp-servers/mcp-config.template.json`** — Ready-to-use template for MCP configuration

## Quick Start

### 1. Install the Instructions File

Copy or symlink `ai-instructions.md` to the location your AI tool expects:

```bash
# Canonical location (recommended)
cp ai-instructions.md ~/.ai-instructions.md

# GitHub Copilot (CLI & VS Code)
mkdir -p ~/.github
ln -sf ~/.ai-instructions.md ~/.github/copilot-instructions.md

# Claude Code (CLAUDE.md)
mkdir -p ~/.claude
ln -sf ~/.ai-instructions.md ~/.claude/CLAUDE.md

# Cursor (global rules)
# Copy content into Cursor Settings > Rules for AI

# Windsurf / Cline
ln -sf ~/.ai-instructions.md ~/.windsurfrules
ln -sf ~/.ai-instructions.md ~/.clinerules

# Aider
ln -sf ~/.ai-instructions.md ~/.aider.conf.yml
# (Aider uses YAML format - adapt content accordingly)
```

### 2. Configure MCP Servers

```bash
# Copy the template to your MCP config location
cp mcp-servers/mcp-config.template.json ~/.copilot/mcp-config.json

# Edit and replace all <PLACEHOLDER> values with your credentials
# NEVER commit the filled-in config to source control
```

### 3. Per-Project Overrides

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

| Tool | Global Config Location | Per-Project |
|------|----------------------|-------------|
| GitHub Copilot CLI | `~/.github/copilot-instructions.md` | `.github/copilot-instructions.md` |
| Claude Code | `~/.claude/CLAUDE.md` | `CLAUDE.md` |
| Cursor | Settings > Rules for AI | `.cursorrules` |
| Windsurf | `~/.windsurfrules` | `.windsurfrules` |
| Cline | `~/.clinerules` | `.clinerules` |
| Aider | `~/.aider.conf.yml` | `.aider.conf.yml` |
| Copilot Workspace | N/A | `AGENTS.md` |

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
