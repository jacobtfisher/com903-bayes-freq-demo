# One Story, Two Inference Machines

**Frequentist and Bayesian inference as tools for theory building in communication.**
An in-class demonstration for COM 903 (Advanced Research Methods), Michigan State University, Fall 2026.

One simulated research program — when a story's main character does a good deed, does rewarding rather than punishing them change how much people enjoy the story? — runs through both statistical frameworks. Affective disposition theory (ADT) predicts it should. At each step the notebook asks **what each framework lets you say** and **what it needs from you**. Because the data are simulated, we know the truth and can check which sentences were warranted.

## Quick start

**Just want to read it?** Open the [site online](https://jacobtfisher.github.io/com903-bayes-freq-demo/), or download this repository and open `docs/index.html` in any browser. Each scene is its own page, with arrows at the bottom to move between them. Every number, figure, and explanation is there; no software needed.

**Want to run it?**

1. Install [R](https://cran.r-project.org/) and [RStudio](https://posit.co/download/rstudio-desktop/) (or Positron).
2. Download this repository (green **Code** button → **Download ZIP**, or `git clone`).
3. Open `com903-bayes-freq-demo.Rproj`.
4. In the console, run `source("install.R")` once.
5. Open any scene (`scene-1.qmd` through `scene-6.qmd`) and run its chunks in order. Each scene loads its own data, so you can start anywhere. To rebuild the whole site, run `quarto render` in the terminal; the pages go to `docs/`.

No Stan or C++ toolchain is needed. Bayesian calculations use grid approximation, closed-form updating, and the [`BayesFactor`](https://cran.r-project.org/package=BayesFactor) package (the engine behind JASP's Bayesian *t*-test).

**Prefer JASP?** The CSVs in `data/` open directly in [JASP](https://jasp-stats.org/). The Resources page maps each result to a JASP menu.

## What's inside

| Scene | Question | Frequentist | Bayesian |
|---|---|---|---|
| 1 · Same data, two questions | What does *p* = .054 license? | *p* value, CI, p-value function | prior × likelihood → posterior; credible interval; P(effect > 0) |
| 2 · Priors as theories | Which theory predicted the data best? | tests of each theory's predicted value | Bayes factors as a prediction contest; prior sensitivity |
| 3 · A theory that predicts nothing | Can we support a boundary condition? | equivalence test (TOST) | BF₀₁ against default and rival alternatives; ROPE |
| 4 · Six labs | Did the effect replicate? | fixed-effect meta-analysis | sequential updating (yesterday's posterior is today's prior) |
| 5 · Neither machine fixes the design | What if people choose their story? | regression with and without adjustment | posteriors and Bayes factors under the same adjustments |
| 6 · What each framework promises | What happens when you peek? | long-run error rates | misleading evidence and sequential designs |

In class we run Scenes 1, 2, and 5 (about 25 minutes). Scenes 3, 4, and 6 are for afterward.

## Repository layout

```
index.qmd                 start page: how to use the site, the running example, the data
scene-1.qmd … scene-6.qmd one page per scene (each runs on its own)
wrap-up.qmd, resources.qmd  summary table; JASP menus, further reading, references
_quarto.yml               site settings: page order, sidebar, back/forward arrows
docs/                     the rendered site (open docs/index.html in a browser)
install.R                 installs the R packages
R/helpers.R               small, commented functions used by the notebook
R/simulate_data.R         rebuilds the datasets; documents every data-generating process
R/check_numbers.R         quick check that the headline numbers haven't drifted
data/                     simulated CSVs + codebook (data/README.md)
Makefile                  shortcuts: make preview / render / check / data
```

## The data

All data are simulated; `data/README.md` is the codebook. Study 1 (15, 50, and 150 per group) has a true standardized effect of δ = 0.30. Study 2 gives the character a morally neutral action instead of a good deed and has a true effect of zero. Study 3 adds five labs running the Study 1 protocol. Study 4 is an observational version in which a pre-existing preference drives both which episode people choose and how much they enjoy it. Seeds were chosen so each dataset illustrates its point cleanly; change them in `R/simulate_data.R` to see how much single studies vary.

## Built on

This demo borrows ideas from, and points students to, these resources:

- Lakens (2022), [*Improving Your Statistical Inferences*](https://lakens.github.io/statistical_inferences/), especially the chapter on [Bayesian statistics](https://lakens.github.io/statistical_inferences/04-bayes.html)
- Kristoffer Magnusson's interactive visualizations of [Bayesian inference](https://rpsychologist.com/d3/bayes/) and [confidence intervals](https://rpsychologist.com/d3/ci/)
- Johnson, Ott, & Dogucu (2022), [*Bayes Rules!*](https://www.bayesrulesbook.com/)
- Papenberg's [`bayesEd`](https://github.com/m-Py/bayesEd), which visualizes the Bayesian *t*-test as competing predictions
- Etz & Vandekerckhove (2018); Greenland et al. (2016); Rohrer (2018); Rouder et al. (2009); Gronau, Ly, & Wagenmakers (2020); Lakens, Scheel, & Isager (2018). Full references are at the end of the notebook.

## License

Code: MIT (see `LICENSE`). Text and figures: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
