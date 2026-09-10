# agent-skills-public

Skills for use through the Codex App, covering academic-paper proofreading and local token-usage reports.

## Available Skills

| Skill | Purpose |
| --- | --- |
| [proofread-paper](skills/proofread-paper/SKILL.md) | Inspect academic PDFs for prose, punctuation, layout, and reference issues using rendered pages and extracted text. |
| [codex-token-usage](skills/codex-token-usage/SKILL.md) | Summarize local token usage and produce hourly, daily, weekly, and monthly text graphs. |

Ask Codex to perform the task using the relevant skill. Codex follows the skill's workflow and runs its helper scripts as needed. See each skill's `SKILL.md` for details.

## Example Requests

With the relevant skill available in the Codex App, try:

- Attach a PDF and ask: "Proofread this paper."
- "Show my token usage for the last two weeks."
- "Summarize my token usage by month."

## Prerequisites

- **Proofreading:** Python 3 with `venv`, plus macOS and a working Swift toolchain. The bundled PDF renderer imports Apple's PDFKit and AppKit frameworks.
- **Token usage:** Bash, `awk`, the `sqlite3` command-line tool, and Python 3 for graphs and daily breakdowns. The Python scripts use only the standard library and do not require a virtual environment.

Token-usage reports require local Codex data. By default, the scripts read `~/.codex/state_5.sqlite`, `~/.codex/sessions/`, and `~/.codex/archived_sessions/` when available. Set `CODEX_HOME` if your data lives elsewhere. These reports describe local client accounting, not final billing.

## Proofreading Environment Setup

You can ask Codex to set up the Python environment in this repository. The commands below are provided for reference; they run from the repository root and create a local virtual environment with the PDF text-extraction dependency:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
```

Codex can verify the dependency with:

```bash
.venv/bin/python -c "import pypdf; print(pypdf.__version__)"
```

The proofreading skill uses `.venv/bin/python` for PDF text checks.

## Local Files

Keep input PDFs, rendered pages, crops, and other scratch files under `tmp/`. The repository ignores `tmp/`, `.venv/`, Python caches, and `.DS_Store`.
