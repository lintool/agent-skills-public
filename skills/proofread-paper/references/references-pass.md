# References Pass

Run this after the layout pass unless the user declines, after a layout-pass decline if the user accepts the references pass, or when the user directly asks about references, bibliography formatting, capitalization in references, or arXiv consistency.

## Visual Reference Inspection

Inspect the rendered References section visually. Do not rely only on extracted text because bibliography styles and PDF extraction can distort case, punctuation, and line breaks.

1. Identify which rendered pages contain the References section.
2. If the reference text is small or crowded, create visible crop files under the same rendered-pages directory in `tmp/`:

```bash
mkdir -p tmp/rendered-pages-PAPERNAME/crops
sips -c HEIGHT WIDTH --cropOffset Y X tmp/rendered-pages-PAPERNAME/page-05.png --out tmp/rendered-pages-PAPERNAME/crops/page-05-refs.png
```

3. Inspect crops at original detail and scan for unusual casing of acronyms, model names, tool names, and dataset names.
4. Report each candidate with reference number, visible title fragment, observed capitalization, and whether it is clearly wrong or a judgment call.
5. End the report with a coverage note naming the References pages or crops inspected.

## Capitalization Patterns

- `LLM`, `LLMs`, not `Llm` or `Llms`
- `ChatGPT`, not `chatgpt` or `Chatgpt`
- `DPR`, not `dpr`
- `RAG`, not `Rag`
- `GPT-OSS-20B` or official lowercase `gpt-oss-20b`, depending on the source/venue style
- `vLLM`, not `Vllm` or `VLLM`, when referring to the vLLM project
- `Pyserini`, `RankLLM`, `FastMCP`, `LlamaIndex`, and `PydanticAI` should preserve their project branding unless the bibliography source intentionally differs

If a title appears with lowercase model names such as `gpt-oss-120b gpt-oss-20b`, treat it as a candidate to review rather than an automatic error, because some official model names are lowercase. Say when a finding is a judgment call.

## arXiv Formatting

Check whether arXiv papers are cited consistently across the bibliography. Look for inconsistent combinations of:

- `arXiv preprint arXiv:NNNN.NNNNN`
- `arXiv:NNNN.NNNNN`
- subject classes such as `[cs.IR]` or `[cs.CL]`
- explicit arXiv URLs such as `https://arxiv.org/abs/NNNN.NNNNN`
- year placement, punctuation, and whether the arXiv identifier appears before or after the URL

Report inconsistent arXiv formatting with reference numbers and visible fragments. Distinguish true inconsistencies from deliberate differences between published venue papers, technical reports, blog posts, and unpublished preprints.
