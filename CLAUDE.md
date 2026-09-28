# CLAUDE.md

Teaching demo for COM 903 (Advanced Research Methods, Michigan State University), Session 4, "Inference and Identification." PhD students in communication follow along in R or read the rendered HTML. The notebook runs one simulated research program through frequentist and Bayesian inference, and asks at each step what each framework lets you say and what it needs from you. The running example is affective disposition theory (ADT): a character does a good deed (returns a lost wallet) and is either rewarded or punished at the end; the outcome is enjoyment of the story (1–7). ADT predicts rewarded > punished. Scene 2 pits ADT (δ ≈ +0.3) against a "craft" account (δ = 0) and a "tragedy" account (δ ≈ −0.3); Scene 3's boundary condition is a morally neutral character, with a "happy ending" account as the rival.

**Working state:** read `dev/refinement-notes.md` first. It records where Jacob's section-by-section review stands, what he has asked for, and which decisions are still open. Update it as you go. It is gitignored.

## Commands

| Task | Command | Time |
|---|---|---|
| Live preview (re-renders the saved page) | `make preview` | ~10–20 s per save |
| Render the whole site into `docs/` | `make render` | ~1–2 min |
| Check headline numbers | `make check` | ~3 s |
| Rebuild datasets | `make data` | ~2 min |
| Install R packages | `make install` | once |

If a page looks stale after editing several files at once, `quarto preview` may have skipped it; render it directly with `quarto render scene-N.qmd` (one file per call), but only after the preview has finished rendering. Two renders of the same page at once collide ("cannot open the connection").

Run `make check` after any change to `R/`, `data/`, or a statistical claim in the prose. Render with a UTF-8 locale; the Makefile sets it. Otherwise δ and − print as `<U+03B4>`.

## Files

- A Quarto website (`_quarto.yml`): `index.qmd` (how to use, running example, data), `scene-1.qmd` … `scene-6.qmd`, `wrap-up.qmd`, `resources.qmd` (JASP appendix, further reading, references). Page order, the sidebar, and the back/forward arrows (`page-navigation`) come from `_quarto.yml`. `docs/` is the rendered site; commit it with the sources. `_quarto.yml`'s `render:` list keeps README.md, CLAUDE.md, and `dev/` out of the site.
- Every scene page starts with the same hidden `setup` chunk and loads its own data, so pages render and run independently. Objects do not carry over between pages.
- `dev/demo-single-page.qmd` / `.html`: the last single-page version (2026-09-28), kept as a fallback.
- `R/helpers.R`: palette, `theme_demo()`, `two_group()`, grid posteriors, the Bayes factor as a prediction contest (`pred_t`, `bf_vs_null`), `tost()`, `update_normal()`, `simulate_study()`, `bf_default()`.
- `R/simulate_data.R`: documents every data-generating process and rebuilds Studies 2–4 and the Scene 6 simulation summary.
- `R/check_numbers.R`: reference values the prose depends on.
- `data/`: CSVs plus a codebook (`data/README.md`).
- `slides/session-4.html`: Jacob's instructor slide deck (self-contained revealjs, speaker notes embedded). Published unlinked at `/slides/session-4.html` via `resources:` in `_quarto.yml`; nothing in the site links to it. Source lives in OneDrive at `COM903_F26/slides/4_inference-identification/`; to update, re-render there and copy the HTML over both `slides/session-4.html` and `docs/slides/session-4.html`.

## Guardrails

- **Never regenerate `story_n15/50/150.csv`.** They match the course notes and the in-class writing prompt (n = 50: 0.42 [−0.01, 0.85], *p* = .054, BF₁₀ = 1.12; n = 150: 0.47 [0.21, 0.72], BF₁₀ = 59).
- **Some numbers are hard-coded in the prose**, for example the Scene 1 "What each framework lets you say" box. When data or methods change, grep `demo.qmd` for the old values. Prefer inline R (`` `r ...` ``) for new numbers.
- **Citations:** never add a reference without first verifying it with a web search: exact authors, year, title, journal, volume, pages, and DOI. Keep the in-text citations and the reference list in sync.
- **Group order:** `ttestBF()`'s formula interface orders groups alphabetically (punished − rewarded). Use `bf_default()` or pass `x`/`y` explicitly.
- **Privacy:** the repo will be public. Do not name students. The running example is "a class example."
- **Do not publish** (`git push`, `gh repo create`, GitHub Pages) until Jacob says so. The publish commands are in `dev/refinement-notes.md`.

## Writing and figure conventions

- Student-facing prose: plain and precise, short paragraphs, active voice, terms defined at first use. Keep the statistical claims exactly right; an independent review already checked them, so don't loosen a caveat when editing for flow.
- Box types (Quarto callouts):
  - `callout-important` titled "Predict first": a pause before a reveal.
  - `callout-note` with `collapse="true"` titled "Explainer: …": definitions.
  - `callout-note` with `appearance="simple"` titled "How to read this figure": a numbered guide after each new figure type.
  - `callout-tip` titled "What each framework lets you say".
  - `callout-warning` titled "Your turn".
- Figures: ggplot with `theme_demo()` and the `pal` colors from `R/helpers.R`. Label series directly on the plot (no legends); `pal` blue, orange, and aqua are a colorblind-validated set, with gray for priors and null references. Big text for the projector. After any figure change, render and look at it for label collisions.
- In class, only Scenes 1, 2, and 5 are shown (about 25 minutes). Scenes 3, 4, and 6 are for after class.
