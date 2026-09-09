# Setup And Render

## Repository Python Environment

Before running this skill in this repository, read the repository-root `README.md` and make sure the documented Python environment is available. First verify the repo-local `.venv` and required packages:

```bash
.venv/bin/python -c "import pypdf"
```

If `.venv/bin/python` or required packages are missing, create the environment and install `requirements.txt`:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install --upgrade pip
.venv/bin/python -m pip install -r requirements.txt
```

Use `.venv/bin/python` for text-assisted PDF checks such as extracting text with `pypdf`. Installing dependencies may require network access and approval; ask for escalation if a required install fails because of sandboxed or unavailable network access.

## Dropped Papers

When the user drags a paper into the Codex App context and asks to proofread it, put the PDF under the repository-root `tmp/input/` directory before running this skill. If the dragged file is already accessible in the workspace, copy it into `tmp/input/` with a clear filename and use that copy as the input PDF. Then render and inspect the `tmp/input/` copy.

If the user does not provide an exact path, locate PDFs with:

```bash
find . -maxdepth 4 -type f -iname '*.pdf' -print
```

## Render PDF Pages

Render the PDF to PNG page images and store them in a visible scratch directory under the repository-root `tmp/` directory. Do not use dot directories such as `.tmp/`; use a plainly visible name containing `rendered-pages`.

```bash
mkdir -p tmp/rendered-pages
skills/proofread-paper/scripts/render_pdf_pages.swift INPUT.pdf tmp/rendered-pages
```

Use a per-document output directory when useful:

```bash
mkdir -p tmp/rendered-pages-PAPERNAME
skills/proofread-paper/scripts/render_pdf_pages.swift INPUT.pdf tmp/rendered-pages-PAPERNAME
```

The renderer writes files named:

```text
page-01.png
page-02.png
...
```

If Swift fails because it cannot write to its module cache, rerun the same command with elevated permissions. This can happen because Swift writes under the user module cache outside the workspace sandbox. Do not install PDF tooling unless the user asks for that explicitly.

## Scratch Artifacts

Rendered PNGs, copied PDFs, and crops are temporary artifacts. Keep them under the repository-root `tmp/` directory unless the user asks to save them elsewhere. Do not commit rendered page images, PDFs the user dropped into the sandbox, `.DS_Store`, or other local scratch artifacts.
