# Layout Pass

Use image viewing on rendered PNGs page by page. Inspect at original detail when proofreading small typography. Whole-page views are not sufficient for detecting small layout issues.

## Mandatory Right-Edge Crop Sweep

Subtle overfull lines and words sticking out past the right edge of a column are often invisible in whole-page views. For every visual proofreading pass that reports on layout, create and inspect zoomed crops around the right edge of each text column and each wide figure/table/caption region before saying that no protrusions were found.

Use a visible crop directory under the rendered-pages directory in `tmp/`:

```bash
mkdir -p tmp/rendered-pages-PAPERNAME/edge-crops
```

Create right-edge crops for each page and column. Adjust crop dimensions and offsets to the rendered page size and paper layout; the crop must include enough of the line endings to establish the normal column edge plus enough margin outside the text block to see whether any glyphs protrude. Do not use crops that are so narrow or misaligned that they hide the local edge comparison; regenerate wider or shifted crops before making any clean claim.

```bash
sips -c HEIGHT WIDTH --cropOffset Y X tmp/rendered-pages-PAPERNAME/page-02.png --out tmp/rendered-pages-PAPERNAME/edge-crops/page-02-left-column-right-edge.png
sips -c HEIGHT WIDTH --cropOffset Y X tmp/rendered-pages-PAPERNAME/page-02.png --out tmp/rendered-pages-PAPERNAME/edge-crops/page-02-right-column-right-edge.png
```

For pages with full-width tables, figures, captions, equations, or reference blocks, also create crops for those region boundaries, not just the body-text columns. Inspect each crop at original detail. Sweep vertically from top to bottom and compare every line end against the local column edge established by nearby normal lines. Pause on any line that reaches farther right than adjacent lines and inspect the final glyphs, including small punctuation such as `).`, commas, periods, quotes, citation brackets, and short trailing words such as `companies`.

## Layout Checklist

- Page edges: content, rules, figures, tables, captions, footnotes, headers, and page furniture should not be clipped or extend into the page margin.
- Column-boundary sweep: in two-column papers, scan the left and right edge of each column from top to bottom for words, punctuation, citations, bullets, formulas, metric names, or figure/table rules that protrude beyond the normal text block. Include body text below wide tables, not just the table itself.
- Line-end protrusion sweep: inspect the right edge of every paragraph line, not only lines with technical tokens. Flag any final word, citation, superscript citation or footnote marker, closing punctuation, metric name, model name, URL, formula, or code-like token that visibly pokes past the otherwise flush column edge.
- Punctuation and short-word check: specifically look for protrusions where the only visible overhang is a closing parenthesis/period pair, quote mark, citation bracket, or a short final word. These are easy to miss because the line still looks visually balanced at whole-page scale.
- Pay special attention to line-final citation clusters with superscript markers because the marker may be the part that protrudes. For example, report a line such as `Arctic-Embed-v2 [44]⁷` when the superscript marker sticks out past the normal column edge.
- Orphan-line sweep: scan every paragraph for isolated lines that contain only a single word, or that are otherwise visibly very short relative to the surrounding paragraph lines. Treat short isolated final lines such as `during tokenization.` as orphan-line layout issues, even when they contain more than one word and even when they are not at a page or column break.
- Mandatory top-of-page/top-of-column orphan sweep: after the whole-page scan, separately inspect the top of every page and the top of every column before checking anything else on that page. Flag any lone carryover line from the previous page or column, especially a short final paragraph line isolated before a new paragraph, subsection, or section heading begins. This includes short carryover lines at the top of a right column, such as `through text messages.` appearing alone before `4.2 Agentic Processes`. Do not overlook these just because the sentence is grammatical across the page or column break; report the visual orphan if it looks awkward.
- When reporting no orphan-line issues, explicitly confirm that top-of-page and top-of-column carryover lines were checked. If this dedicated sweep was not completed, state that limitation instead of saying no orphan lines were found.
- Floating objects: check that boxes, shaded table rows, diagrams, code blocks, and highlighted text stay aligned with their intended column or full-width region.
- Captions and footnotes: check that long captions, footnote rules, and footnote text do not overhang their column or collide with nearby content.

## Reporting Layout Results

For each layout finding, identify the visual issue only; do not suggest a fix.

If any word, citation, superscript marker, metric name, URL, formula, or punctuation extends visibly beyond the normal right column edge, report it as a line-end protrusion with page, column/region, and surrounding visible text. Include protrusions caused only by final punctuation or short trailing words.

Do not dismiss protrusions as harmless just because they remain within the physical page margin; the check is against the normal text block or column edge.

Do not say `no column-boundary protrusions`, `no line-end protrusions`, or `layout looks clean` unless the right-edge crop sweep was completed for every rendered page and relevant region. If the sweep was not completed, state that limitation explicitly instead of giving a clean layout assessment.

End the layout report with a coverage note naming the rendered pages, crop directory, and relevant page regions inspected.
