# agent-skills-public

Reusable agent skills and helper scripts for academic-paper proofreading and local Codex token-usage reports.

## Available Skills

| Skill | Purpose |
| --- | --- |
| [proofread-paper](skills/proofread-paper/SKILL.md) | Inspect academic PDFs for prose, punctuation, layout, and reference issues using rendered pages and extracted text. |
| [codex-token-usage](skills/codex-token-usage/SKILL.md) | Summarize local token usage and produce hourly, daily, weekly, and monthly text graphs. |

See each skill's `SKILL.md` for its workflow. Run the commands below from the repository root.

## Prerequisites

- **Proofreading:** Python 3 with `venv`, plus macOS and a working Swift toolchain. The bundled PDF renderer imports Apple's PDFKit and AppKit frameworks.
- **Token usage:** Bash, `awk`, the `sqlite3` command-line tool, and Python 3 for graphs and daily breakdowns. The Python scripts use only the standard library and do not require a virtual environment.

Token-usage reports require local Codex data. By default, the scripts read `~/.codex/state_5.sqlite`, `~/.codex/sessions/`, and `~/.codex/archived_sessions/` when available. Set `CODEX_HOME` if your data lives elsewhere. These reports describe local client accounting, not final billing.

## Set Up the Proofreading Environment

Create a repository-local virtual environment and install the PDF text-extraction dependency:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
```

Verify the dependency:

```bash
.venv/bin/python -c "import pypdf; print(pypdf.__version__)"
```

Use `.venv/bin/python` for PDF text checks. You can optionally activate the environment with `source .venv/bin/activate`.

## Example Commands

### Render a Paper

Place a PDF at `tmp/input/paper.pdf`, then run:

```bash
mkdir -p tmp/input tmp/rendered-pages-paper
skills/proofread-paper/scripts/render_pdf_pages.swift tmp/input/paper.pdf tmp/rendered-pages-paper
```

The renderer writes `page-01.png`, `page-02.png`, and so on. Follow the [proofreading workflow](skills/proofread-paper/SKILL.md) to inspect the rendered pages and perform the text, layout, and reference passes.

### Report Token Usage

Show totals and recent tasks:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh
```

Show a daily graph for the last 14 days:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --graph-days 14
```

List command options:

```bash
skills/codex-token-usage/scripts/codex_token_usage.sh --help
```

## Local Files

Keep input PDFs, rendered pages, crops, and other scratch files under `tmp/`. The repository ignores `tmp/`, `.venv/`, Python caches, and `.DS_Store`.
