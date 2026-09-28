# Data codebook

All datasets are **simulated**. `R/simulate_data.R` rebuilds them and documents each data-generating process. Ratings are rounded to the 1–7 scale.

The running example: participants read a short story in which the main character does a good deed (returning a lost wallet with the cash untouched). In the **rewarded** ending, the owner gives the character a cash reward; in the **punished** ending, the owner accuses the character of stealing and calls the police. The outcome is how much participants enjoyed the story. Affective disposition theory (ADT) predicts more enjoyment after the rewarded ending.

## Study 1 — randomized story study

`story_n15.csv`, `story_n50.csv`, `story_n150.csv` (15, 50, and 150 participants per group)

| Column | Meaning |
|---|---|
| `id` | participant ID |
| `condition` | `rewarded` or `punished`: how the story ends for the character who did the good deed |
| `enjoyment` | how much the participant enjoyed the story, 1 (not at all) to 7 (very much) |

Truth: standardized effect δ = 0.30 (rewarded − punished), SD = 1.2, punished mean 4.24. These three files were generated on 2026-09-15 and are kept verbatim so results match the course notes; `R/simulate_data.R` checks them against reference values.

## Study 2 — boundary condition (a morally neutral character)

`story_neutral_n200.csv` — same columns plus `action` (`neutral`). The character does something morally neutral instead of a good deed, then meets the same rewarded or punished ending. ADT predicts no effect, because viewers form no disposition toward the character. 200 per group. Truth: δ = 0.

## Study 3 — six labs

`story_labs.csv` — same columns plus `lab` (1–6) and `n_per_group`. Lab 1 is `story_n50.csv`; labs 2–6 are new samples of 40, 60, 30, 80, and 45 per group. Truth: δ = 0.30 in every lab.

## Study 4 — observational platform data

`story_observational.csv` — 600 viewers who chose which version of the episode to watch.

| Column | Meaning |
|---|---|
| `id` | viewer ID |
| `just_world` | standardized preference for stories where good is rewarded (a pre-existing trait) |
| `chose_rewarded` | 1 = chose the version where the good deed is rewarded, 0 = chose the version where it is punished |
| `satisfaction` | satisfaction with the ending: did the character get what they deserved? (measured after viewing; a mediator) |
| `enjoyment` | how much the viewer enjoyed the story, 1–7 |

Truth: `just_world` causes both choice and enjoyment (a confounder). The total causal effect of the rewarded episode is 0.36 scale points, of which 0.20 runs through `satisfaction` and 0.16 is direct.

## Scene 6 — simulation summary

`sim_peeking_summary.csv` — for true δ = 0 and δ = 0.30, the share of 2,000 simulated studies meeting each criterion at 10–100 participants per group, with one look (`fixed_*`), with a look every 10 participants (`peek_*`), and in a two-boundary sequential Bayes factor design (`sbf_end_h1`, `sbf_end_h0`).
