# Text-Assisted Pass

Run this as the second pass, immediately after rendering and before layout inspection.

When this file is loaded for any text-assisted pass, scan for every issue type in this file, including tense consistency, Oxford comma usage, and footnote/punctuation spacing. For targeted text requests, emphasize the requested check in the report, but still include any confirmed findings from the other mandatory text checks under their own headings.

## Extract Text

Use `.venv/bin/python` and `pypdf` to extract page text:

```bash
.venv/bin/python -c "from pypdf import PdfReader; r=PdfReader('INPUT.pdf'); print('\n\n--- PAGE BREAK ---\n\n'.join((p.extract_text() or '') for p in r.pages))"
```

Treat extracted text as a candidate generator only. PDF extraction can introduce missing spaces, wrong symbols, broken ligatures, and line-order errors. Visually confirm every reported finding against the rendered page.

## What To Scan

- likely typos, missing spaces, doubled words, punctuation issues, and awkward prose
- terminology inconsistencies, especially model names, dataset names, metric names, and abbreviations
- table-value anomalies or rows where percentages do not match counts
- caption/text mismatches, such as table numbers, model names, and fusion names
- capitalization of technical terms in body text
- tense consistency across the paper
- missing Oxford commas in visible serial lists outside the bibliography
- footnote/punctuation spacing in both possible orders

## Tense Consistency

Always check tense consistency during any text-assisted pass. Report tense findings separately from typos and other proofreading issues.

1. Identify the paper's dominant tense from the abstract, introduction, methodology, experiments, and conclusion. Do not force a change if different sections intentionally use different tenses for different rhetorical purposes.
2. If the paper is mostly in present tense, flag completed-study phrasing such as `we conducted`, `we generated`, `we observed`, `we compiled`, `were recruited`, `were instructed`, `was applied`, and `was used` when comparable surrounding prose uses present tense.
3. If the paper is mostly in past tense, flag present-tense descriptions of completed work such as `we conduct`, `we generate`, `we observe`, `we compile`, `is applied`, and `is used` when comparable surrounding prose uses past tense.
4. Do not flag adjectival or noun-modifying forms such as `human-written narratives`, `generated narratives`, `style-transformed counterpart`, or `published work` unless the surrounding sentence has an actual tense inconsistency.
5. For each tense finding, give the page or section, the visible phrase, and a suggested rewrite in the chosen dominant tense.

In the final report, use a separate `Tense Consistency` section. Put typos, grammar, punctuation, layout, and reference issues in separate sections so tense edits are not mixed with ordinary proofreading findings.

## Footnote And Punctuation Spacing

Always check footnote and punctuation spacing during any text-assisted pass. When reporting a spacing issue, clarify the visual pattern:

- Footnote before punctuation with a space: `word¹ .`
- Punctuation before footnote with a space: `word. ¹`

Search visually for both patterns. Footnote markers may appear as superscript digits near the baseline of the surrounding punctuation, so rely on rendered page images rather than extracted text.

## Oxford Comma

Always check Oxford comma usage outside the bibliography during any text-assisted pass. The user uses the Oxford comma. Catch all visible cases where a serial comma is missing in a list of three or more items, including body text, captions, table text, acknowledgments, and figure labels. Report the page number and visible phrase, and suggest the corrected form with the comma before the final `and` or `or`.

Examples to flag:

- `A, B and C` should be `A, B, and C`
- `A, B or C` should be `A, B, or C`
- `A, B, C and D` should be `A, B, C, and D`

Do not flag two-item lists, fixed official titles, quoted source text, code, mathematical notation, or bibliography entries. When uncertain, report it as a judgment call.

## Reporting

Report findings with page number, column or section if visible, and the surrounding visible text. Put typo, grammar, punctuation, terminology, and content/table-value issues under a prose or content section, not under layout.

If a candidate appears only in extracted text but is visually correct in the rendered page, do not report it as a finding.
