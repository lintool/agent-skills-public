---
name: proofread-paper
description: Visually proofread academic papers from PDFs, especially layout, punctuation, footnote placement, figure captions, reference formatting, and other typeset-paper issues. Use when the user asks to inspect or proofread a PDF paper visually, including requests to find spacing or punctuation problems that text extraction may miss.
---

# Proofread Paper

Use this skill when proofreading a PDF paper benefits from rendered-page inspection plus text-assisted checks. Keep context small: load only the phase references needed for the current pass.

## Phase References

- `references/setup-render.md`: Always load first. Covers repo environment, dropped PDFs, rendering, and scratch-file rules.
- `references/text-pass.md`: Load for normal proofreading and run as the second pass, immediately after rendering. Covers text extraction, candidate generation, visual confirmation, prose issues, terminology, table-value sanity checks, and mandatory checks for tense consistency, Oxford commas, and footnote/punctuation spacing.
- `references/layout-pass.md`: Load after reporting text-pass findings unless the user declines the layout pass. Covers whole-page inspection, mandatory right-edge crop sweep, protrusions, orphan lines, figures, captions, and footnotes.
- `references/references-pass.md`: Load after the layout pass or after the user declines the layout pass, unless the user declines the references pass. Covers bibliography/reference formatting, capitalization, arXiv style, and reference consistency.

## Default Workflow

For a general "proofread this PDF" request:

1. Load `references/setup-render.md`.
2. Copy or locate the PDF as directed there, verify the repo Python environment, and render pages.
3. Load `references/text-pass.md` and run the text-assisted pass second. Treat extracted text as a candidate generator, visually confirm findings before reporting, and always check tense consistency, Oxford comma usage, and footnote/punctuation spacing.
4. Stop and report findings from the text pass before starting any layout pass. Report by category, with page number, column or section if visible, and surrounding visible text. Include a coverage note that says which rendered pages were visually checked. Then ask exactly: `Do you want me to continue with the layout pass?`
5. Continue to `references/layout-pass.md` unless the user declines. When doing the layout pass, complete the visual layout pass, including the required right-edge crop sweep before any clean layout claim. Stop and report layout findings before starting any references pass. Include a coverage note that says which pages and right-edge crops were inspected. Then ask exactly: `Do you want me to continue with the references pass?`
6. If the user declines the layout pass, still ask exactly: `Do you want me to continue with the references pass?`
7. Continue to `references/references-pass.md` unless the user declines. Stop and report references findings after completing the pass. Include a coverage note that says which References pages or crops were inspected.

Report findings after each completed pass. Proactively offer the layout pass after the text pass, and proactively offer the references pass after the layout pass or after a layout-pass decline. Skip either pass only if the user declines.

## Direct Targeted Requests

If the user asks only for a specific pass, still load `references/setup-render.md`, locate or copy the PDF, verify the environment needed for that pass, and render pages first. Then run only the requested pass unless another pass is needed to classify a candidate finding. After reporting that pass, proactively offer the remaining downstream passes in normal order, skipping only if the user declines.

Examples:

- For "only check layout", render pages, load `references/layout-pass.md`, run the full layout pass, report layout findings and coverage, then ask whether to continue with the references pass.
- For "only check references", render pages, load `references/references-pass.md`, run the references pass, and report references findings and coverage. Do not run text or layout unless the user asks.
- For "only check tense" or another text-specific request, render pages, load `references/text-pass.md`, run the requested text check with visual confirmation, report findings and coverage, then ask whether to continue with the layout pass.

## Reporting

- Keep tense-consistency findings separate from typos, grammar, punctuation, layout, and reference findings.
- Distinguish related but different issues, such as punctuation before a footnote marker with extra spacing (`text. ¹² Next`) versus footnote marker before punctuation with a space (`text¹² .`).
- If no matching issue is found, say that explicitly and mention whether the check was visual across all rendered pages.
- After every pass, include a short coverage note naming the pages, crops, or rendered-page set inspected and any limits.
